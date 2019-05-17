//
//  HiNetworkHTTPStatusCode.h
//  NetworkKit
//
//  Created by JT Ma on 2019/3/18.
//  Copyright © 2019 mutating. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, HiNetworkHTTPStatusCode) {
    HiNetworkHTTPStatusCodeZero                              =   0,
    
    // 1xx Informational
    HiNetworkHTTPStatusCodeContinue                          = 100,
    HiNetworkHTTPStatusCodeSwitchingProtocols                = 101,
    HiNetworkHTTPStatusCodeProcessing                        = 102,
    
    // 2xx Success
    HiNetworkHTTPStatusCodeOK                                = 200,
    HiNetworkHTTPStatusCodeCreated                           = 201,
    HiNetworkHTTPStatusCodeAccepted                          = 202,
    HiNetworkHTTPStatusCodeNonAuthoritativeInformation       = 203,
    HiNetworkHTTPStatusCodeNoContent                         = 204,
    HiNetworkHTTPStatusCodeResetContent                      = 205,
    HiNetworkHTTPStatusCodePartialContent                    = 206,
    HiNetworkHTTPStatusCodeMultiStatus                       = 207,
    HiNetworkHTTPStatusCodeAlreadyReported                   = 208,
    HiNetworkHTTPStatusCodeIMUsed                            = 226,
    
    // 3xx Redirection
    HiNetworkHTTPStatusCodeMultipleChoices                   = 300,
    HiNetworkHTTPStatusCodeMovedPermanently                  = 301,
    HiNetworkHTTPStatusCodeFound                             = 302,
    HiNetworkHTTPStatusCodeSeeOther                          = 303,
    HiNetworkHTTPStatusCodeNotModified                       = 304,
    HiNetworkHTTPStatusCodeUseProxy                          = 305,
    HiNetworkHTTPStatusCodeUnused                            = 306,
    HiNetworkHTTPStatusCodeTemporaryRedirect                 = 307,
    HiNetworkHTTPStatusCodePermanentRedirect                 = 308,
    
    // 4xx Client Error
    HiNetworkHTTPStatusCodeBadRequest                        = 400,
    HiNetworkHTTPStatusCodeUnauthorized                      = 401,
    HiNetworkHTTPStatusCodePaymentRequired                   = 402,
    HiNetworkHTTPStatusCodeForbidden                         = 403,
    HiNetworkHTTPStatusCodeNotFound                          = 404,
    HiNetworkHTTPStatusCodeMethodNotAllowed                  = 405,
    HiNetworkHTTPStatusCodeNotAcceptable                     = 406,
    HiNetworkHTTPStatusCodeProxyAuthenticationRequired       = 407,
    HiNetworkHTTPStatusCodeRequestTimeout                    = 408,
    HiNetworkHTTPStatusCodeConflict                          = 409,
    HiNetworkHTTPStatusCodeGone                              = 410,
    HiNetworkHTTPStatusCodeLengthRequired                    = 411,
    HiNetworkHTTPStatusCodePreconditionFailed                = 412,
    HiNetworkHTTPStatusCodePayloadTooLarge                   = 413,
    HiNetworkHTTPStatusCodeURITooLong                        = 414,
    HiNetworkHTTPStatusCodeUnsupportedMediaType              = 415,
    HiNetworkHTTPStatusCodeRangeNotSatisfiable               = 416,
    HiNetworkHTTPStatusCodeExpectationFailed                 = 417,
    HiNetworkHTTPStatusCodeIamATeapot                        = 418,
    HiNetworkHTTPStatusCodeMisdirectedRequest                = 421,
    HiNetworkHTTPStatusCodeUnprocessableEntity               = 422,
    HiNetworkHTTPStatusCodeLocked                            = 423,
    HiNetworkHTTPStatusCodeFailedDependency                  = 424,
    HiNetworkHTTPStatusCodeUpgradeRequired                   = 426,
    HiNetworkHTTPStatusCodeUnavailableForLegalReasons        = 451,
    
    // 5xx Server Error
    HiNetworkHTTPStatusCodeInternalServerError               = 500,
    HiNetworkHTTPStatusCodeNotImplemented                    = 501,
    HiNetworkHTTPStatusCodeBadGateway                        = 502,
    HiNetworkHTTPStatusCodeServiceUnavailable                = 503,
    HiNetworkHTTPStatusCodeGatewayTimeout                    = 504,
    HiNetworkHTTPStatusCodeHTTPVersionNotSupported           = 505,
    HiNetworkHTTPStatusCodeVariantAlsoNegotiates             = 506,
    HiNetworkHTTPStatusCodeInsufficientStorage               = 507,
    HiNetworkHTTPStatusCodeLoopDetected                      = 508,
    HiNetworkHTTPStatusCodeBandwidthLimitExceeded            = 509,
    HiNetworkHTTPStatusCodeNotExtended                       = 510
};
