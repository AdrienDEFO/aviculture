# Script to prepare and copy the Python model to the package

# This script should be run after generating avimodel.pkl in Python

# Copy the pickle file to the package
import shutil
import os

source = "d:\\projet\\Avipro\\avimodel.pkl"
destination = "d:\\projet\\Avipro\\aviculture\\inst\\extdata\\avimodel.pkl"

if os.path.exists(source):
    shutil.copy2(source, destination)
    print(f"✓ Model copied to: {destination}")
else:
    print(f"⚠ Source file not found: {source}")
    print("Please run the Python script Interpolation.py first to generate avimodel.pkl")



