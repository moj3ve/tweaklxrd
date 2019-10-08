#import <Cephei/HBPreferences.h>


static NSDictionary *replacement = @{
    @"fullX": @{
        @"10": @"X",
        @"x": @"X",
        @"o": @"x",
        @"O": @"x",
    },
    @"x": @{
        @"X": @"x",
        @"10": @"x",
        @"o": @"x",
        @"O": @"x",
    },
};

static NSString *mode = nil;

NSString *owoify (NSString *text, bool replacementOnly) {
    NSString *temp = [text copy];
    
    if (replacement[mode]) {
        for (NSString *key in replacement[mode]) {
            temp = [temp stringByReplacingOccurrencesOfString:key withString:replacement[mode][key]];
        }
    }

    if (replacementOnly) return temp;


    return temp;
}

%group OwONotifications

%hook NCNotificationContentView

-(void)setPrimaryText:(NSString *)orig {
    if (!orig) {
        %orig(orig);
        return;
    }
    
    %orig(owoify(orig, true));
}

-(void)setSecondaryText:(NSString *)orig {
    if (!orig) {
        %orig(orig);
        return;
    }
    
    %orig(owoify(orig, false));
}

%end

%end

%group OwOEverywhere

%hook UILabel

-(void)setText:(NSString *)orig {
    if (!orig) {
        %orig(orig);
        return;
    }
    
    %orig(owoify(orig, true));
}

%end

%end

%group OwOIconLabels

%hook SBIconLabelImageParameters

-(NSString *)text {
    return owoify(%orig, true);
}

%end

%end

%group OwOSettings

%hook PSSpecifier

-(NSString *)name {
    return owoify(%orig, true);
}

%end

%end

%ctor {
    if (![NSProcessInfo processInfo]) return;
    NSString *processName = [NSProcessInfo processInfo].processName;
    bool isSpringboard = [@"SpringBoard" isEqualToString:processName];

    // Someone smarter than me invented this.
    // https://www.reddit.com/r/jailbreak/comments/4yz5v5/questionremote_messages_not_enabling/d6rlh88/
    bool shouldLoad = NO;
    NSArray *args = [[NSClassFromString(@"NSProcessInfo") processInfo] arguments];
    NSUInteger count = args.count;
    if (count != 0) {
        NSString *executablePath = args[0];
        if (executablePath) {
            NSString *processName = [executablePath lastPathComponent];
            BOOL isApplication = [executablePath rangeOfString:@"/Application/"].location != NSNotFound || [executablePath rangeOfString:@"/Applications/"].location != NSNotFound;
            BOOL isFileProvider = [[processName lowercaseString] rangeOfString:@"fileprovider"].location != NSNotFound;
            BOOL skip = [processName isEqualToString:@"AdSheet"]
                        || [processName isEqualToString:@"CoreAuthUI"]
                        || [processName isEqualToString:@"InCallService"]
                        || [processName isEqualToString:@"MessagesNotificationViewService"]
                        || [executablePath rangeOfString:@".appex/"].location != NSNotFound;
            if ((!isFileProvider && isApplication && !skip) || isSpringboard) {
                shouldLoad = YES;
            }
        }
    }

    if (!shouldLoad) return;

    HBPreferences *file = [[HBPreferences alloc] initWithIdentifier:@"com.daveapps.tweaklxrd"];

    if ([([file objectForKey:@"Enabled"] ?: @(YES)) boolValue]) {
        mode = [file objectForKey:@"Style"] ?: @"fullX";

        if ([([file objectForKey:@"EnabledEverywhere"] ?: @(NO)) boolValue]) {
            %init(OwOEverywhere);
        }

        if ([([file objectForKey:@"EnabledSettings"] ?: @(NO)) boolValue]) {
            %init(OwOSettings);
        }

        if (isSpringboard) {
            if ([([file objectForKey:@"EnabledNotifications"] ?: @(YES)) boolValue]) {
                %init(OwONotifications);
            }

            if ([([file objectForKey:@"EnabledIconLabels"] ?: @(NO)) boolValue]) {
                %init(OwOIconLabels);
            }
        }
    }
}
