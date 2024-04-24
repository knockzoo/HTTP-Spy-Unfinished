# HTTP Spy v5
This is not a comprehensive version of finished product.
This is purely just the functional aspect of the final product - and does not contain any of the user interface or other user-experience neccesaties.

Once this has been fully finished (including the UI) and it's been properly tested & debugged, a release will be made to the original HTTP spy repository.

## Added Features
This version demo's new features intended to help reduce detections and provide a more sophisticated approach.

The full list of features:
- IP address spoofing
  1. Spoofs any instances of your IP address which have been sent or received by the client,
  2. This does **NOT** replace the functionality of a VPN, and will not work against server-side based IP occurences,
- HWID Spoofing
  1. Same as above but for your client's Roblox-based HWID,
  2. Will not impact the HWID provided by your executor in requests,
- Request Proxying
  1. A built in proxy is provided which will reroute your traffic to a third party server,
  2. Currently, we do not provide a privacy policy - this is used entirely at your own descretion,
  3. A FOSS implementation of the backend will be provided at a later date which will allow users to build their own backends,
  4. This **will** properly spoof your IP address,
  5. This feature is not very reliable, and is error-prone. Not recommended for actual use outside of testing.
- Enhanced Bypasses
  1. The HTTP spy will now make proper attempts at concealing itself
     1. Objects are removed from the garbage collector
     2. Tables will be deepcloned without calling `pairs`/`next` (frequently used for detections)
     3. The random number generator uses a harder to predict seed - meaning any detections which would, for example, try to predict any spoofed IP addresses should no longer work
- Re-worked Data Serialization
  1. The HTTP Spy now uses the data serializer I recently uploaded in a seperate repository, which should provide a slightly different and more readable output
- Improved Code Quality & Readability
  1. This release uses a proper project environment, with improved all around code quality and far more documentation
