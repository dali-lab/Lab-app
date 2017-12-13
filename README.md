# DALI Lab App
The DALI app is an app for DALI members and affiliates to provide features and information to maximize the effectiveness of DALI. The iOS app boasts a list of events, a live posting of food, an interface of changing the lights, and a list of members currently in the lab space. The tvOS app has the same list of members and events and food, but also shows a slideshow of photos and welcomes members into the lab.

## Screenshots

<center>
![](http://is4.mzstatic.com/image/thumb/Purple118/v4/55/ba/59/55ba59cf-0519-43f1-2851-9c9d91c6b1e4/source/392x696bb.jpg)
![](http://is2.mzstatic.com/image/thumb/Purple118/v4/fe/e1/f2/fee1f274-91d4-8e3c-bb68-4cb081b1df75/source/392x696bb.jpg)
</center>

## Other documentation

## Getting Started
To get started with development on this repository, clone the repository. Make sure you have Xcode installed. This Xcode project uses cocoapods for thirdparty package management, so you will need to install this as well:

```bash
brew install cocoapods
```

When cocoapods has been installed, navigate to the cloned repository and run:

```bash
pod install
```

which will download and integrate all the needed packages.

### Code structure
The code is split up into the different projects, and all shared code is in the [DALI framework](https://github.com/dali-lab/DALI-Framework). Each file has a description of its use, and all major functions describe what they do and how they should be used.

## Contributors
> John Kotz