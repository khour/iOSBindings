Want some Cocoa Bindings for your iOS App?
-------------------------

This humble project is a port of basic (and most useful, in my authoritarian opinion) Cocoa Bindings functionality to iOS.

Sample usage:

        [target kh_bind:@"foo.bar" toObject:source withKeyPath:@"bar.foo" options:nil];

Now target.foo.bar is updated live alongside with source.bar.foo and vice versa.

To be updated and extended
-------------------------
* Binding options
* ObjectController and ArrayController
* Action bindings
