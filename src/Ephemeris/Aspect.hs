{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE RecordWildCards #-}
module Ephemeris.Aspect where

import Import
import Utils
import Ephemeris.Types
import Ephemeris.Utils
import RIO.List (headMaybe)

majorAspects :: [Aspect]
majorAspects =
    [ Aspect{ aspectType = Major, aspectName = Conjunction, angle = 0.0, maxOrb = 10.0, temperament = Synthetic }
    , Aspect{ aspectType = Major, aspectName = Sextile, angle = 60.0, maxOrb = 6.0, temperament = Synthetic }
    , Aspect{ aspectType = Major, aspectName = Square, angle = 90.0, maxOrb = 10.0, temperament = Analytical }
    , Aspect{ aspectType = Major, aspectName = Trine, angle = 120.0, maxOrb = 10.0, temperament = Synthetic }
    , Aspect{ aspectType = Major, aspectName = Opposition, angle = 180.0, maxOrb = 10.0, temperament = Analytical }
    ]


minorAspects :: [Aspect]
minorAspects =
    [ Aspect { aspectType = Minor, aspectName = SemiSquare, angle = 45.0, maxOrb = 3.0, temperament = Analytical }
    , Aspect { aspectType = Minor, aspectName = Sesquisquare, angle = 135.0, maxOrb = 3.0, temperament = Analytical }
    , Aspect { aspectType = Minor, aspectName = SemiSextile, angle = 30.0, maxOrb = 3.0, temperament = Neutral }
    , Aspect { aspectType = Minor, aspectName = Quincunx, angle = 150.0, maxOrb = 3.0, temperament = Neutral }
    , Aspect { aspectType = Minor, aspectName = Quintile, angle = 72.0, maxOrb = 2.0, temperament = Synthetic }
    , Aspect { aspectType = Minor, aspectName = BiQuintile, angle = 144.0, maxOrb = 2.0, temperament = Synthetic }
    ]

defaultAspects :: [Aspect]
defaultAspects = majorAspects <> minorAspects

aspects' :: (HasLongitude a, HasLongitude b) => [Aspect] -> [a] -> [b] -> [HoroscopeAspect a b]
aspects' possibleAspects bodiesA bodiesB =
  (concatMap aspectsBetween pairs) & catMaybes
  where
    pairs = [(x, y) | x <- bodiesA, y <- bodiesB]
    aspectsBetween bodyPair = map (haveAspect bodyPair) possibleAspects
    haveAspect (a, b) asp@Aspect {..} =
      let angleBetween = angularDifference (getLongitudeRaw a) (getLongitudeRaw b)
          orbBetween = (angle - (abs angleBetween)) & abs
       in if orbBetween <= maxOrb
            then Just $ HoroscopeAspect {aspect = asp, bodies = (a, b), aspectAngle = angleBetween, orb = orbBetween}
            else Nothing

aspects :: (HasLongitude a, HasLongitude b) => [a] -> [b] -> [HoroscopeAspect a b]
aspects = aspects' defaultAspects

planetaryAspects :: [PlanetPosition] -> [HoroscopeAspect PlanetPosition PlanetPosition]
planetaryAspects ps = aspects ps $ rotateList 1 ps

celestialAspects :: [PlanetPosition] -> Angles -> [HoroscopeAspect PlanetPosition House]
celestialAspects ps Angles {..} = aspects ps [House I (Longitude ascendant) 0, House X (Longitude mc) 0]

findAspectBetweenPlanets :: [HoroscopeAspect PlanetPosition PlanetPosition] -> Planet -> Planet -> Maybe (HoroscopeAspect PlanetPosition PlanetPosition)
findAspectBetweenPlanets aspectList pa pb =
  aspectList
    & filter (\HoroscopeAspect {..} -> (planetName . fst $ bodies, planetName . snd $ bodies) `elem` [(pa, pb), (pb, pa)])
    & headMaybe

findAspectWithAngle :: [HoroscopeAspect PlanetPosition House] -> Planet -> HouseNumber -> Maybe (HoroscopeAspect PlanetPosition House)
findAspectWithAngle aspectList pa hb =
  aspectList
    & filter (\HoroscopeAspect {..} -> (planetName . fst $ bodies, houseNumber . snd $ bodies) == (pa, hb))
    & headMaybe

findAspectsByName :: [HoroscopeAspect a b] -> AspectName -> [HoroscopeAspect a b]
findAspectsByName aspectList name =
  aspectList
    & filter (\HoroscopeAspect {..} -> (aspect & aspectName) == name)