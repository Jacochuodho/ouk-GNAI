#!/usr/bin/env python3
"""Vehicle Parts Guessing Game (Scale-Agnostic)

Play a configurable guessing game where the player must guess a vehicle part.
The game is "scale-agnostic": parts are grouped by scale (small/medium/large)
and the same gameplay/hint system works across scales.

Features:
- Choose scale: small/medium/large (changes part pool size/complexity)
- Configurable attempts
- Hints revealed progressively on incorrect guesses: function, location,
  material, masked name
- Non-interactive/testing helpers: --part to force the target part (deterministic),
  and EOF-safe input handling so the script works when piped.
"""

from __future__ import annotations

import argparse
import random
import sys
from typing import Dict, List


class VehiclePartsGame:
    def __init__(self, attempts: int = 5, scale: str = "medium", seed: int | None = None, forced_part: str | None = None):
        self.attempts = attempts
        self.scale = scale
        self.seed = seed
        if seed is not None:
            random.seed(seed)

        # Parts database grouped by scale; discoverable and data-driven
        # Each part has: name, function, location, material
        self.parts: Dict[str, List[Dict[str, str]]] = {
            "small": [
                {"name": "bolt", "function": "fastens components together", "location": "through holes/joints", "material": "steel", "failure_modes": "corrosion, shear, loosening", "maintenance": "torque to spec; inspect for corrosion"},
                {"name": "nut", "function": "secures bolts and threaded fasteners", "location": "threaded studs/joints", "material": "steel", "failure_modes": "stripping, corrosion", "maintenance": "replace if threads damaged; use locking compound when needed"},
                {"name": "washer", "function": "distributes load under fasteners", "location": "under nuts/bolts", "material": "steel/plastic", "failure_modes": "wear, deformation", "maintenance": "inspect for deformation; replace worn washers"},
                {"name": "spark plug", "function": "ignite the air/fuel mixture", "location": "engine cylinder", "material": "ceramic/metal", "failure_modes": "fouling, electrode wear", "maintenance": "inspect/replace at intervals; check gap"},
                {"name": "fuse", "function": "protect electrical circuits", "location": "fuse box", "material": "metal/plastic", "failure_modes": "blow from overload", "maintenance": "replace with correct rating; diagnose root cause"},
                {"name": "sensor", "function": "measure physical parameters (temp/pressure)", "location": "engine or systems", "material": "plastic/metal", "failure_modes": "drift, open circuit", "maintenance": "clean connectors; replace faulty sensors"},
                {"name": "o-ring", "function": "seal fluid passages", "location": "joints/seals", "material": "rubber", "failure_modes": "hardening, cracking, extrusion", "maintenance": "replace during service; use correct material and lubricant"},
            ],
            "medium": [
                {"name": "brake pad", "function": "provide friction to slow wheels", "location": "brake caliper", "material": "friction material/metal", "failure_modes": "wear, glazing", "maintenance": "inspect thickness; replace in pairs"},
                {"name": "brake rotor", "function": "surface for brake pads to squeeze", "location": "wheel hub", "material": "cast iron/steel", "failure_modes": "warping, scoring", "maintenance": "resurface or replace if beyond spec"},
                {"name": "caliper", "function": "house brake pads and apply pressure", "location": "around wheel/rotor", "material": "aluminum/steel", "failure_modes": "seized pistons, leaks", "maintenance": "inspect seals and pistons; rebuild or replace"},
                {"name": "alternator", "function": "generate electrical power", "location": "engine bay", "material": "metal", "failure_modes": "diode or bearing failure", "maintenance": "check charging voltage; replace faulty alternator"},
                {"name": "battery", "function": "store electrical energy", "location": "engine bay/trunk", "material": "lead/acid/plastic", "failure_modes": "capacity loss, sulfation", "maintenance": "check voltage and load; replace if weak"},
                {"name": "radiator", "function": "cool engine coolant", "location": "front of vehicle", "material": "aluminum/plastic", "failure_modes": "leaks, clogging", "maintenance": "flush coolant; repair or replace leaking cores"},
                {"name": "fuel pump", "function": "deliver fuel to engine", "location": "fuel tank/engine bay", "material": "metal/plastic", "failure_modes": "failure under load, debris-clogging", "maintenance": "replace fuel filter; test pump pressure"},
                {"name": "exhaust muffler", "function": "reduce exhaust noise", "location": "underbody/exhaust system", "material": "steel", "failure_modes": "corrosion, internal damage", "maintenance": "inspect for rust and leaks; replace if damaged"},
                {"name": "wheel", "function": "support and move the vehicle", "location": "axle/hub", "material": "rubber/metal", "failure_modes": "tire wear, rim damage", "maintenance": "check tire pressure and tread; inspect rims"},
            ],
            "large": [
                {"name": "engine", "function": "produce mechanical power", "location": "engine bay", "material": "metal", "failure_modes": "overheating, oil leaks, bearing wear", "maintenance": "regular oil changes; monitor coolant and oil levels"},
                {"name": "transmission", "function": "transfer power to wheels", "location": "between engine and driveshaft", "material": "metal", "failure_modes": "slipping, fluid leaks", "maintenance": "service fluid and filter; diagnose slipping"},
                {"name": "chassis", "function": "support structure of vehicle", "location": "entire vehicle", "material": "steel/aluminum", "failure_modes": "corrosion, structural damage", "maintenance": "inspect for rust and damage; repair as needed"},
                {"name": "axle", "function": "support wheels and transmit torque", "location": "underbody/axle housing", "material": "steel", "failure_modes": "bending, bearing failure", "maintenance": "inspect bearings; check alignment"},
                {"name": "suspension", "function": "absorb shocks and maintain ride quality", "location": "between wheels and chassis", "material": "metal/rubber", "failure_modes": "worn bushings, leaking shocks", "maintenance": "inspect bushings and shocks; replace worn parts"},
                {"name": "drivetrain", "function": "deliver power from engine to wheels", "location": "entire powertrain", "material": "metal", "failure_modes": "u-joint/drive shaft wear", "maintenance": "inspect joints and boots; lubricate where applicable"},
                {"name": "body", "function": "enclose passengers and cargo", "location": "external vehicle structure", "material": "steel/aluminum/composite", "failure_modes": "corrosion, panel damage", "maintenance": "repair dents; treat rust promptly"},
                {"name": "cab", "function": "driver/passenger compartment", "location": "front/mid section", "material": "steel/glass", "failure_modes": "seal leaks, interior wear", "maintenance": "inspect seals; maintain interior components"},
            ],
        }

        if forced_part:
            # If forced_part is provided, try to use it (case-insensitive match)
            self.target = self._find_part_by_name(forced_part)
            if not self.target:
                raise ValueError(f"Forced part '{forced_part}' not found in parts database")
        else:
            pool = self.parts.get(self.scale)
            if not pool:
                raise ValueError(f"Unknown scale '{self.scale}', choose from: {list(self.parts.keys())}")
            self.target = random.choice(pool)

        # Hint order and internal state (now includes failure modes and maintenance tips)
        self.hints = ["function", "location", "material", "failure_modes", "maintenance", "masked"]
        self.hint_index = 0

    def _find_part_by_name(self, name: str) -> Dict[str, str] | None:
        lname = name.strip().lower()
        for pool in self.parts.values():
            for p in pool:
                if p["name"].lower() == lname:
                    return p
        return None

    def masked_name(self) -> str:
        # Return the part name masked with underscores except vowels revealed progressively
        name = self.target["name"]
        chars = []
        for ch in name:
            if ch.isspace() or not ch.isalpha():
                chars.append(ch)
            else:
                chars.append("_")
        # reveal a few letters depending on hint_index
        reveal = max(1, self.hint_index)  # reveal at least 1 letter past initial
        alpha_positions = [i for i, c in enumerate(name) if c.isalpha()]
        for pos in alpha_positions[:reveal]:
            chars[pos] = name[pos]
        return "".join(chars)

    def give_hint(self) -> str:
        key = self.hints[min(self.hint_index, len(self.hints) - 1)]
        if key == "masked":
            return f"Name pattern: {self.masked_name()}"
        return f"{key.capitalize()}: {self.target[key]}"

    def process_guess(self, guess: str) -> bool:
        if guess.strip().lower() == self.target["name"].lower():
            return True
        return False

    def play(self) -> None:
        print(f"Scale: {self.scale} | Attempts: {self.attempts}")
        print("Try to guess the vehicle part. Hints will be revealed after wrong guesses.")

        while self.attempts > 0:
            # Always show current hint (starts with function)
            print(self.give_hint())
            try:
                guess = input("Your guess: ")
            except EOFError:
                print("\nNo more input. Exiting game.")
                return

            if self.process_guess(guess):
                print("Correct! Well done.")
                return
            else:
                print("Not correct.")
                self.attempts -= 1
                self.hint_index += 1
                if self.attempts > 0:
                    print(f"Attempts left: {self.attempts}\n")

        print(f"Out of attempts. The answer was: {self.target['name']}")


def main(argv: List[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Vehicle Parts Guessing Game (scale-agnostic)")
    parser.add_argument("--scale", choices=["small", "medium", "large"], default="medium", help="Select part scale/pool")
    parser.add_argument("--attempts", type=int, default=5, help="Number of attempts")
    parser.add_argument("--seed", type=int, default=None, help="Random seed for deterministic behavior")
    parser.add_argument("--part", type=str, default=None, help="(testing) force a specific target part by exact name")
    args = parser.parse_args(argv)

    game = VehiclePartsGame(attempts=args.attempts, scale=args.scale, seed=args.seed, forced_part=args.part)
    game.play()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
