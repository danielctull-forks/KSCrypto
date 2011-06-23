//
//  KSSHA1Stream.h
//  Sandvox
//
//  Created by Mike on 12/03/2011.
//  Copyright 2011 Karelia Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CommonCrypto/CommonDigest.h>

typedef void (^KSSHA1StreamCompletionBlock) (NSData *SHA1Digest);
typedef void (^KSSHA1StreamFailureBlock) (NSError *error);


@interface KSSHA1Stream : NSOutputStream
{
  @private
    CC_SHA1_CTX _ctx;
    NSData      *_digest;
	KSSHA1StreamCompletionBlock _completionBlock;
	KSSHA1StreamFailureBlock _failureBlock;
}

// nil until you call -close
@property(nonatomic, copy, readonly) NSData *SHA1Digest;

+ (KSSHA1Stream *)SHA1StreamWithURL:(NSURL *)URL 
					completionBlock:(KSSHA1StreamCompletionBlock)completionBlock
					   failureBlock:(KSSHA1StreamFailureBlock)failureBlock;

- (id)initWithURL:(NSURL *)URL 
  completionBlock:(KSSHA1StreamCompletionBlock)block
	 failureBlock:(KSSHA1StreamFailureBlock)failureBlock;
@end

#pragma mark -


@interface NSData (KSSHA1Stream)

// Cryptographic hashes
- (NSData *)ks_SHA1Digest;
- (NSString *)ks_SHA1DigestString;

@end
