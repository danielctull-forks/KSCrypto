//
//  KSSHA1Stream.m
//  Sandvox
//
//  Created by Mike on 12/03/2011.
//  Copyright 2011 Karelia Software. All rights reserved.
//

#import "KSSHA1Stream.h"


@implementation KSSHA1Stream

@synthesize SHA1Digest = _digest;

- (id)init;
{
    if (self = [super init])
    {
        CC_SHA1_Init(&_ctx);
    }
    return self;
}

- (void)close;
{
    unsigned char digest[CC_SHA1_DIGEST_LENGTH];
	CC_SHA1_Final(digest, &_ctx);
	
    _digest = [[NSData alloc] initWithBytes:digest length:CC_SHA1_DIGEST_LENGTH];

	if (_completionBlock) _completionBlock([self SHA1Digest]);
}

- (void)dealloc;
{
	[_completionBlock release];
	[_failureBlock release];
    [_digest release];
    [super dealloc];
}

- (NSInteger)write:(const uint8_t *)buffer maxLength:(NSUInteger)len;
{
    CC_SHA1_Update(&_ctx, buffer, len);
    return len;
}

+ (KSSHA1Stream *)SHA1StreamWithURL:(NSURL *)URL
					completionBlock:(KSSHA1StreamCompletionBlock)completionBlock 
					   failureBlock:(KSSHA1StreamFailureBlock)failureBlock
{
	return [[[self alloc] initWithURL:URL completionBlock:completionBlock failureBlock:failureBlock] autorelease];
}

- (id)initWithURL:(NSURL *)URL 
  completionBlock:(KSSHA1StreamCompletionBlock)completionBlock 
	 failureBlock:(KSSHA1StreamFailureBlock)failureBlock
{
    if (self = [self init]) 
	{
		_completionBlock = [completionBlock copy];
		_failureBlock = [failureBlock copy];
		
		if ([URL isFileURL]) 
		{
			NSInputStream *stream = [[NSInputStream alloc] initWithFileAtPath:[URL path]];
			[stream open];
			
#define READ_BUFFER_SIZE 64*CC_SHA1_BLOCK_BYTES
			
			uint8_t buffer[READ_BUFFER_SIZE];
			
			while ([stream streamStatus] < NSStreamStatusAtEnd)
			{
				NSInteger length = [stream read:buffer maxLength:READ_BUFFER_SIZE];
				
				if (length > 0)
				{
					NSInteger written = [self write:buffer maxLength:length];
					OBASSERT(written == length);
				}
			}
			
			[stream release];
			[self close];
		}
		else
		{
			[NSURLConnection connectionWithRequest:[NSURLRequest requestWithURL:URL] delegate:self];
		}
		
	}
    return self;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self write:[data bytes] maxLength:[data length]];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [self close];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    _digest = [[NSData alloc] init];
	
	if (_failureBlock) failureBlock(error);
}

@end

#pragma mark -

@implementation NSData (KSSHA1Stream)

- (NSData *)ks_SHA1Digest
{
	KSSHA1Stream *stream = [[KSSHA1Stream alloc] init];
    [stream write:[self bytes] maxLength:[self length]];
    [stream close];
    NSData *result = [[[stream SHA1Digest] copy] autorelease];
    
    [stream release];
    return result;
}

- (NSString *)ks_SHA1DigestString
{
	static char sHEHexDigits[] = "0123456789abcdef";
	
    NSData *digestData = [self ks_SHA1Digest];
    unsigned char *digest = (unsigned char *)[digestData bytes];
    
	unsigned char digestString[2 * CC_SHA1_DIGEST_LENGTH];
    NSUInteger i;
	for (i=0; i<CC_SHA1_DIGEST_LENGTH; i++)
	{
		digestString[2*i]   = sHEHexDigits[digest[i] >> 4];
		digestString[2*i+1] = sHEHexDigits[digest[i] & 0x0f];
	}
    
	return [[[NSString alloc] initWithBytes:(const char *)digestString
                                     length:2 * CC_SHA1_DIGEST_LENGTH
                                   encoding:NSASCIIStringEncoding] autorelease];
}

@end
