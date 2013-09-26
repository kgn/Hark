Hark is a text to speech app I built in 3 hours based on the new [`AVSpeechSynthesizer`](https://developer.apple.com/library/ios/documentation/AVFoundation/Reference/AVSpeechSynthesizer_Ref/Reference/Reference.html) SDK in iOS 7.

I first learned about this SDK from [Mattt Thompson](https://twitter.com/mattt)'s great [NSHipster blog post about iOS 7](https://nshipster.com/ios7).

![](https://raw.github.com/kgn/Hark/master/screen.png)

Check out [this video](https://vimeo.com/75465205) showing how the app works and why I built it.

This app will be available on the App Store for free and I'm releasing the source as an example for other developers to encourage you to put text to speech in your apps!

Here are some features you might want to borrow for you're apps:
- `UIMenuItem` to read the currently selected text
- Language voice detection
- Read the entire document or the selected text
- Detect new text in the clipboard
- Starting and stopping the reading. For simplicity I didn't add pausing but you might want to.

#Todo

- Improved app communication, probably via url schemes
- Buttons to dismiss the keyboard and clear the text view, probably above the keyboard
- Settings for reading speed and voice selection

# Credits

Be sure to [follow me](https://twitter.com/iamkgn) on twitter!

Thanks to [Eric Wolfe](https://github.com/ericrwolfe) for his awesome language voice detection pull request!

Special thanks to [Mattt Thompson](https://twitter.com/mattt) for bringing `AVSpeechSynthesizer` to my attention, [Drew Wilson](https://twitter.com/drewwilson) for the [Execute](http://executebook.com) book and mentality, and [Sam Soffes](https://twitter.com/soffes) for convincing me to open source this project!
