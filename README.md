[![GitHub License](https://img.shields.io/github/license/XCEssentials/ByTypeStorage.svg?longCache=true)](LICENSE)
[![GitHub Tag](https://img.shields.io/github/tag/XCEssentials/ByTypeStorage.svg?longCache=true)](https://github.com/XCEssentials/ByTypeStorage/tags)
[![Swift Package Manager Compatible](https://img.shields.io/badge/SPM-compatible-brightgreen.svg?longCache=true)](Package.swift)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-brightgreen.svg?longCache=true)](https://github.com/Carthage/Carthage)
[![Written in Swift](https://img.shields.io/badge/Swift-5.0-orange.svg?longCache=true)](https://swift.org)
[![Supported platforms](https://img.shields.io/badge/platforms-macOS%20%7C%20iOS%20%7C%20tvOS%20%7C%20watchOS%20%7C%20Linux-blue.svg?longCache=true)](Package.swift)
[![Build Status](https://travis-ci.com/XCEssentials/ByTypeStorage.svg?branch=master)](https://travis-ci.com/XCEssentials/ByTypeStorage)

# ByTypeStorage

Data container that allows to store exactly one instance of any given type



## How it works

It's Dictionary-like (and Dictionary-based) key-value storage where key is derived from a type provided. Internally keys are just strings generated from a given value type full name (that includes module name, and all parent types in case of nested types). This feature allows to avoid the need of hard-coded string-based keys, improves type-safety, simplifies usage. Obviously, this data container is supposed to be used with custom data types that have some domain-specific semantics in their names and every value associated with this type supposed to be unique within each given storage.