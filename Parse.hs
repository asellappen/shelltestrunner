module Parse
where

import Control.Applicative ((<$>))
import Control.Monad (liftM,when)
import Data.Maybe (isNothing,catMaybes)
import Text.ParserCombinators.Parsec
import Text.Printf (printf)

import PlatformString (fromPlatformString)
import Types
-- import Utils

-- import qualified Hledger.Utils (trace,strace,ptrace)


-- dbg = False
ptrace_ _s -- | dbg       = Hledger.Utils.ptrace s
          | otherwise = return ()
ptrace _s _a -- | dbg       = Hledger.Utils.ptrace $ s ++ ": " ++ show a
           | otherwise = return ()

parseShellTestFile :: Bool -> FilePath -> IO (Either ParseError [ShellTest])
parseShellTestFile debug f = do
  p <- parseFromFile shelltestfilep f
  case p of
    Right ts -> do
           let ts' | length ts > 1 = [t{testname=testname t++":"++show n} | (n,t) <- zip ([1..]::[Int]) ts]
                   | otherwise     = ts
           when (debug) $ do
             printf "parsed %s:\n" $ fromPlatformString f
             mapM_ (putStrLn.(' ':).show) ts'
           return $ Right ts'
    Left _ -> do
           when (debug) $ printf "failed to parse any tests in %s\n" $ fromPlatformString f
           return p

shelltestfilep :: Parser [ShellTest]
shelltestfilep = do
  ptrace_ "shelltestfilep 0"
  ts <- concat `fmap` many (try inputthentestsp <|> ((:[]) `fmap` try testwithinputp))
  ptrace "shelltestfilep 1" ts
  skipMany whitespaceorcommentlinep
  ptrace_ "shelltestfilep 2"
  eof
  ptrace_ "shelltestfilep ."
  return ts

-- input followed by tests

inputthentestsp :: Parser [ShellTest]
inputthentestsp = do
  ptrace_ " inputthentestsp 0"
  skipMany whitespaceorcommentlinep
  ptrace_ " inputthentestsp 1"
  i <- optionMaybe inputp <?> "input"
  ptrace " inputthentestsp i" i
  ts <- many1 $ try (testafterinputp i)
  ptrace_ " inputthentestsp ."
  return ts

testafterinputp :: Maybe String -> Parser ShellTest
testafterinputp i = do
  ptrace_ "  testafterinputp 0"
  skipMany whitespaceorcommentlinep
  ptrace_ "  testafterinputp 1"
  c <- commandp' <?> "command line"
  ptrace "  testafterinputp c" c
  o <- optionMaybe expectedoutputp <?> "expected output"
  ptrace "  testafterinputp o" o
  e <- optionMaybe expectederrorp <?> "expected error output"
  ptrace "  testafterinputp e" e
  x <- expectedexitcodep <?> "expected exit status"
  ptrace "  testafterinputp x" x
  when (null (show c) && (isNothing i) && (null $ catMaybes [o,e]) && null (show x)) $ fail ""
  f <- fromPlatformString . sourceName . statePos <$> getParserState
  let t = ShellTest{testname=f,command=c,stdin=i,stdoutExpected=o,stderrExpected=e,exitCodeExpected=x}
  ptrace "  testafterinputp ." t
  return t

-- a test with its own input

testwithinputp :: Parser ShellTest
testwithinputp = do
  ptrace_ " testwithinputp 0"
  skipMany whitespaceorcommentlinep
  ptrace_ " testwithinputp 1"
  c <- commandp <?> "command line"
  ptrace " testwithinputp c" c
  i <- optionMaybe inputp <?> "input"
  ptrace " testwithinputp i" i
  o <- optionMaybe expectedoutputp <?> "expected output"
  ptrace " testwithinputp o" o
  e <- optionMaybe expectederrorp <?> "expected error output"
  ptrace " testwithinputp e" e
  x <- expectedexitcodep <?> "expected exit status"
  ptrace " testwithinputp x" x
  when (null (show c) && (isNothing i) && (null $ catMaybes [o,e]) && null (show x)) $ fail ""
  f <- fromPlatformString . sourceName . statePos <$> getParserState
  let t = ShellTest{testname=f,command=c,stdin=i,stdoutExpected=o,stderrExpected=e,exitCodeExpected=x}
  ptrace " testwithinputp ." t
  return t

newlineoreofp, whitespacecharp :: Parser Char
linep,lineoreofp,whitespacep,whitespacelinep,commentlinep,whitespaceorcommentlinep,whitespaceorcommentlineoreofp,delimiterp,inputp :: Parser String
linep = (anyChar `manyTill` newline) <?> "rest of line"
newlineoreofp = newline <|> (eof >> return '\n') <?> "newline or end of file"
lineoreofp = (anyChar `manyTill` newlineoreofp)
whitespacecharp = oneOf " \t"
whitespacep = many whitespacecharp
whitespacelinep = try (newline >> return "") <|> try (whitespacecharp >> whitespacecharp `manyTill` newlineoreofp)
commentlinep = try (whitespacep >> char '#' >> lineoreofp) <?> "comments"
whitespaceorcommentlinep = commentlinep <|> whitespacelinep
whitespaceorcommentlineoreofp = choice [(eof >> return ""), commentlinep, whitespacelinep]
delimiterp = choice [string "$$$", string "<<<", try $ string ">>>", eof >> return ""]

commandp,fixedcommandp,replaceablecommandp :: Parser TestCommand
commandp = optional (string "$$$") >> (fixedcommandp <|> replaceablecommandp)
commandp' = string "$$$" >> (fixedcommandp <|> replaceablecommandp)
fixedcommandp = many1 whitespacecharp >> linep >>= return . FixedCommand
replaceablecommandp = linep >>= return . ReplaceableCommand

inputp = try $ string "<<<" >> whitespaceorcommentlinep >> (liftM unlines) (linep `manyTill` (lookAhead delimiterp))

expectedoutputp :: Parser Matcher
expectedoutputp = (try $ do
  string ">>>" >> optional (char '1')
  whitespacep
  choice [positiveregexmatcherp, negativeregexmatcherp, whitespaceorcommentlineoreofp >> linesmatcherp]
 ) <?> "expected output"

expectederrorp :: Parser Matcher
expectederrorp = (try $ do
  string ">>>2"
  whitespacep
  choice [positiveregexmatcherp, negativeregexmatcherp, (whitespaceorcommentlineoreofp >> linesmatcherp)]
 ) <?> "expected error output"

expectedexitcodep :: Parser Matcher
expectedexitcodep = (try $ do
  string ">>>="
  whitespacep
  choice [positiveregexmatcherp, try negativeregexmatcherp, numericmatcherp, negativenumericmatcherp]
 ) <?> "expected exit status"

linesmatcherp :: Parser Matcher
linesmatcherp = do
  ln <- liftM sourceLine getPosition
  (liftM $ Lines ln . unlines) (linep `manyTill` (lookAhead delimiterp)) <?> "lines of output"

negativeregexmatcherp :: Parser Matcher
negativeregexmatcherp = (do
  char '!'
  PositiveRegex r <- positiveregexmatcherp
  return $ NegativeRegex r) <?> "non-matched regexp pattern"

positiveregexmatcherp :: Parser Matcher
positiveregexmatcherp = (do
  char '/'
  r <- (try escapedslashp <|> noneOf "/") `manyTill` (char '/')
  whitespaceorcommentlineoreofp
  return $ PositiveRegex r) <?> "regexp pattern"

negativenumericmatcherp :: Parser Matcher
negativenumericmatcherp = (do
  char '!'
  Numeric s <- numericmatcherp
  return $ NegativeNumeric s
  ) <?> "non-matched number"

numericmatcherp :: Parser Matcher
numericmatcherp = (do
  s <- many1 $ oneOf "0123456789"
  whitespaceorcommentlineoreofp
  return $ Numeric s
  ) <?> "number"

escapedslashp :: Parser Char
escapedslashp = char '\\' >> char '/'

-- | Try to parse this shelltest file and return the number of tests
-- parsed (0 on parse error). Best with dbg=True.
testparse f = parseFromFile shelltestfilep f  >>= return . either (const 0) length
