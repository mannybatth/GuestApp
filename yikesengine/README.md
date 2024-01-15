# README #

This is the Single-Path Engine for iOS as of November 2015.

## Special note - July 2016

This framework is currently (July 2016) used in conjunction with the Generic Engine to allow the MP Engine to be supported without interfering with the new SP Engine. Since MP is being deprecated / sunset since Mid-May 2016 and should be shut down entirely by Mid-September, the Generic Engine can be left behind and archived along with the MP Engine.

### What is this repository for? ###

* This repository contains the source code to build and package the Single-Path Yikes Engine "Framework" to be distributed and linked against any iOS native application.
* Version: See the "CFBundleShortVersionString" in the Info.plist under YikesEngine / YikesEngine

### How do I get set up? ###

* Summary of set up
* Configuration
* Dependencies: See the "Dependencies folder".
* Database configuration - the database is self-contained.
* How to run tests - see the test target.
* Deployment instructions - see the following tutorial: https://www.raywenderlich.com/126365/ios-frameworks-tutorial

### Contribution guidelines ###

* Writing tests - any method that applies an algorithm or implements a formula and requires precise and consistent results should have unit tests.
* Code review - before starting development of a new feature or a bug fix, create a new branch under the feature path (i.e. feature/ticketnumber-my-awesome-branch) from develop. Once done, submit a Pull Request to a member of the team for review before merge.