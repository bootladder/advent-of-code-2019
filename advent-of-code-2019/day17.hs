import Intcode
import Data.Char
import Data.Array
import Debug.Trace

-- the input string is printed top to bottom
-- so (0,0) is the top left, (X,Y) is bottom right
stringToGrid :: String -> Array (Int,Int) Char
stringToGrid str =
  let
    ySize = length $ lines str
    xSize = length $ head $ lines str

    getRowIndicies y =
      let rowValues = (lines str) !! y
      in map (\x -> ((x,y), rowValues !! x) ) [0..xSize - 1]

    indicies = concat $ map getRowIndicies [0..ySize - 1]
  in
    array (((0),(0)),(xSize-1,ySize-1)) $ indicies

gridToString :: Array (Int,Int) Char -> String
gridToString grid =
  let (xSize,ySize) = snd $ bounds grid
      showRow y = map (\x -> grid ! (x,y) ) [0..xSize]
  in
    concat $ map (\y -> (++) (showRow y) "\n") [0..ySize]


getScaffoldingMapString :: IO String
getScaffoldingMapString =
  do
    inputString <- readFile "day17-input.txt" >>= (pure . init)

    let
      csInitial = defaultComputerState { program = parseProgram inputString}
      csNext = runProgram csInitial
      scaffoldingMapString = map chr $ outputBuffer csNext

    return $ reverse $ dropWhile (== '\n') $ reverse scaffoldingMapString  --remove newlines

getIntersections :: Array (Int,Int) Char -> [(Int,Int)]
getIntersections grid =
  filter (\index -> isIntersection grid index) $ indices grid

isIntersection :: Array (Int,Int) Char -> (Int,Int) -> Bool
isIntersection grid (x,y) =
  let (xMax, yMax) = snd $ bounds grid
  in
    --trace ("(x,y) = (" ++ (show x) ++ ", " ++ (show y) ++ ")" ++ " = " ++ (show $ grid ! (x,y))) $
    if x == 0 || y == 0 || x == xMax || y == yMax  || (grid ! (x,y) /= '#')
    then False
    else
      if (grid ! (x+1,y)) == '#' &&
         (grid ! (x-1,y)) == '#' &&
         (grid ! (x,y+1)) == '#' &&
         (grid ! (x,y-1)) == '#'
      then True
      else False

main1 :: IO ()
main1 = do
  scaffoldingMapString <- getScaffoldingMapString
  let
    scaffoldingMapGrid = stringToGrid scaffoldingMapString

  putStrLn $ scaffoldingMapString
  putStrLn $ show scaffoldingMapGrid
  putStrLn $ show $ bounds scaffoldingMapGrid
  putStrLn $ gridToString scaffoldingMapGrid

  let
    intersections = getIntersections scaffoldingMapGrid
    alignmentParameters = map (\(x,y) -> x*y) intersections
    answer = sum $ map (\(x,y) -> x*y) intersections

  putStrLn $ show intersections
  putStrLn $ show alignmentParameters
  putStrLn $ show answer
  putStrLn "hello"

getIntcodeProgram :: IO Program
getIntcodeProgram =
  do
    inputString <- readFile "day17-input.txt" >>= (pure . init)
    return $ parseProgram inputString

getRobotPosition :: Array (Int,Int) Char -> (Int,Int)
getRobotPosition grid =
  head $ filter (isRobotMarker grid) $ indices grid
  where isRobotMarker grid index =
          if grid ! index /= '#' &&
             grid ! index /= '.'
          then True
          else False

-- eg. ['F', F', 'R', 'F', 'F', 'L', 'F']
-- robot will never go backward
traceScaffolding :: Array (Int,Int) Char -> (Int,Int) -> [(Char,Int)] -> [(Char,Int)]
traceScaffolding grid pos steps =
  --trace ("NEW RUN:: STEPS :: " ++ (show steps)) $
  if isAtTheEnd grid pos (fst $ head steps)
  then
    --trace "AAA" $
    steps
  else
    let (currentDirection, currentDistance) = last steps
    in
      --trace "BBB" $
      if canGoForward grid pos currentDirection
      then
        let updateSteps = (init steps) ++ [(currentDirection, currentDistance + 1)]
        in
          --trace "CCC" $
          traceScaffolding grid (movePositionForward pos currentDirection) updateSteps
      else
        --trace "DDD" $
        if canGoLeft grid pos currentDirection
        then traceScaffolding grid pos (steps ++ [(leftOf currentDirection, 0)])
        else
          if canGoRight grid pos currentDirection
          then traceScaffolding grid pos (steps ++ [(rightOf currentDirection, 0)])
          else
            steps

canGoForward :: Array (Int,Int) Char -> (Int,Int) -> Char -> Bool
canGoForward grid (x,y) direction =
  let ((_,_), (maxX, maxY)) = bounds grid
  in
    case direction of
      'N' -> if (y /= 0) && grid ! (x,y-1) == '#' then True else False -- North is minus y
      'S' -> if (y /= maxY) && grid ! (x,y+1) == '#' then True else False -- South is plus y
      'E' -> if (x /= maxX) && grid ! (x+1,y) == '#' then True else False
      'W' -> if (x /= 0) && grid ! (x-1,y) == '#' then True else False


movePositionForward :: (Int,Int) -> Char -> (Int,Int)
movePositionForward (x,y) 'N' = (x,y-1) -- North is minus y
movePositionForward (x,y) 'S' = (x,y+1) -- South is plus y
movePositionForward (x,y) 'E' = (x+1,y)
movePositionForward (x,y) 'W' = (x-1,y)
movePositionForward _ _ = (0,0)

leftOf ::  Char -> Char
leftOf 'N' = 'W'
leftOf 'S' = 'E'
leftOf 'E' = 'N'
leftOf 'W' = 'S'
leftOf _ = 'Z'

rightOf ::  Char -> Char
rightOf 'N' = 'E'
rightOf 'S' = 'W'
rightOf 'E' = 'S'
rightOf 'W' = 'N'
rightOf _ = 'Z'

canGoLeft :: Array (Int,Int) Char -> (Int,Int) -> Char -> Bool
canGoLeft grid pos direction = canGoForward grid pos (leftOf direction)

canGoRight :: Array (Int,Int) Char -> (Int,Int) -> Char -> Bool
canGoRight grid pos direction = canGoForward grid pos (rightOf direction)

isAtTheEnd :: Array (Int,Int) Char -> (Int,Int) -> Char -> Bool
isAtTheEnd grid (x,y) direction =
  -- ie. can't go in any other directions
  let
    otherDirections = filter (/= direction) ['N','S','E','W']
  in and $ map (\dir -> False == canGoForward grid (x,y) dir) otherDirections


cardinalSteps2LeftRightSteps :: [(Char,Int)] -> [(Char,Int)]
cardinalSteps2LeftRightSteps [] = []
cardinalSteps2LeftRightSteps (_:[]) = []
cardinalSteps2LeftRightSteps (cardinalStep1:cardinalStep2:steps) =
  let leftRightStep = ((leftOrRight (fst cardinalStep1) (fst cardinalStep2)) , (snd cardinalStep2) )
  in
    [leftRightStep] ++ cardinalSteps2LeftRightSteps ([cardinalStep2] ++ steps)

leftOrRight :: Char -> Char -> Char
leftOrRight 'N' 'W' = 'L'
leftOrRight 'N' 'E' = 'R'
leftOrRight 'S' 'E' = 'L'
leftOrRight 'S' 'W' = 'R'
leftOrRight 'E' 'N' = 'L'
leftOrRight 'E' 'S' = 'R'
leftOrRight 'W' 'N' = 'R'
leftOrRight 'W' 'S' = 'L'
leftOrRight _ _  = 'Z'

leftRightStepsToASCII :: [(Char,Int)] -> String
leftRightStepsToASCII steps =
  init $ concat $ map showStep steps -- remove trailing comma
  where showStep (direction, distance) =
          [direction] ++ "," ++ (show distance) ++ ","


routines :: [ (Char, [(Char,Int)]) ] --routine name, list of left/right, distance
routines =
  [
    ('A', [('L',10), ('R',8), ('R',8)])
  , ('B', [('L',10), ('L',12),('R',8),('R',10)])
  , ('C', [('R',10),('L',12),('R',10)])
  ]

matchRoutine :: [(Char,Int)] -> [(Char, [(Char,Int)])] -> Maybe Char
matchRoutine _ [] = Nothing
matchRoutine steps (routine:routines) =
  -- match routines with the beginning of the step list
  let routineLength = length $ snd routine
  in
    if (length steps >= routineLength) && (snd routine) == (take routineLength steps)
    then
      Just $ fst routine
    else matchRoutine steps routines

routineLength :: [(Char, [(Char,Int)])] -> Char -> Int
routineLength routines c =
  let found = filter (\(char, _) -> char == c) routines
  in
    length $ snd $ head found

substituteRoutines :: [(Char,Int)] -> [(Char, [(Char,Int)])] -> [(Char,Int)] -> [(Char,Int)]
substituteRoutines [] _ acc = acc
substituteRoutines steps routines acc =
  --trace ("running substitute :: ACC :: " ++ (show acc)) $
  --trace ("running substitute :: steps :: " ++ (show steps)) $
  case matchRoutine steps routines of
    Nothing -> substituteRoutines (tail steps) routines (acc ++ [head steps])
    Just routineId ->
      --trace "MATCH"
      substituteRoutines (drop (routineLength routines routineId) steps) routines (acc ++ [(routineId, 999)])

routine2ASCII :: (Char, [(Char,Int)]) -> String
routine2ASCII routine =
  leftRightStepsToASCII $ snd routine

main :: IO ()
main = do
  grid <- (getScaffoldingMapString >>= (\s -> return $ stringToGrid s))
  program <- getIntcodeProgram
  let
    programWithWakeup = program // [(0, 2)]
    robotPosition = getRobotPosition grid

    steps = traceScaffolding grid robotPosition [('N', 0)]  --north is decreasing y
    leftRightSteps = cardinalSteps2LeftRightSteps steps
    asciiSteps = leftRightStepsToASCII leftRightSteps

    routinesSubstited = substituteRoutines leftRightSteps routines []
    mainASCIISequenceNoCommas = (map (ord . fst) routinesSubstited)
    mainASCIISequenceWithCommas = init $ (concat $ map (\i -> [i] ++ [ord ',']) mainASCIISequenceNoCommas) -- remove trailing comma
    mainASCIISequence = mainASCIISequenceWithCommas ++ [10]  --newline

    routinesASCIISequences = map (\r -> (routine2ASCII r) ++ "\n" ) routines
    routinesCombined = map ord $ concat routinesASCIISequences

    programInput = mainASCIISequence ++ routinesCombined ++ (map ord "n\n")

    csInitial = defaultComputerState { program = programWithWakeup, inputBuffer = programInput}
    csNext = runProgram csInitial
    

  putStrLn $ gridToString grid
  putStrLn $ show robotPosition
  putStrLn $ show steps
  putStrLn "\n"
  putStrLn $ show leftRightSteps
  putStrLn $ show $ length leftRightSteps
  putStrLn $ "asciiSteps : " ++ (show asciiSteps)
  putStrLn $ "Length : " ++ (show $ length asciiSteps)
  putStrLn $ "Routines Subsitutude:  " ++ (show routinesSubstited)
  putStrLn $ "MAIN ROUTNIE ASCII:  " ++ (show mainASCIISequence)
  putStrLn $ "Routines ASCII:  " ++ (show routinesCombined)
  putStrLn $ "PROGRAM INPUT :  " ++ (show programInput)
  putStrLn $ "OUTPUT BUFFER :  " ++ (show $ map chr $ outputBuffer csNext)

  putStrLn $ "RESULT : " ++ (show csNext)
  putStrLn "hello"
