# HTTP Spy v5
This is not a comprehensive version or finished product.
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
     4. Original function's debug information is preserved
     5. Bypasses for anti HTTP spies that look for constants within the garbage collector, such as function's containing `hookfunction` are now spoofed
     6. Envrionment based bypasses *may* prevent anti HTTP spies which use getfenv(0).script based detections
     7. More bypasses for preventing data from being recovered via the garbagecollector, now certain values are removed on a Lua interpreter level as opposed to just hiding them from `getgc` results
     8. RNG has a reworked seed generator, and should now be significantly harder to predict
     9. Traceback information is now dynamically spoofed, and it should be harder to detect the request hooks
     10. Metatables are now hidden from `getmetatable`
- Re-worked Data Serialization
  1. The HTTP Spy now uses the data serializer I recently uploaded in a seperate repository, which should provide a slightly different and more readable output
- Improved Code Quality & Readability
  1. This release uses a proper project environment, with improved all around code quality and far more documentation

## Liability & Usage Expectations
I am not liable for any damages caused by the usage of this project.
This project is not intended for and is not encouraged to be used for illegal or unauthorized penetrational testing or otherwise illegal or condemned actions.
You are expected to use this within any terms and conditions or any expectations that are applicable.

**Please, do not use this on a whitelist without permission.**
