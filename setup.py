#!/usr/bin/env python3
# file: setup.py
from setuptools import setup

setup(
    name='sops-precommit-hook',
    version='1.0.0',
    py_modules=['sops_precommit_hook'],
    install_requires=[
        'PyYAML>=6.0',
    ],
    entry_points={
        'console_scripts': [
            'sops-precommit-hook=sops_precommit_hook:main',
        ],
    },
    python_requires='>=3.8',
)
