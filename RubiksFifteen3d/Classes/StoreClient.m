//
//  StoreClient.m
//  RubiksFifteen3d
//
//  Created by Oliver Klemenz on 18.11.12.
//  Copyright 2013. All rights reserved.
//

#import "StoreClient.h"
#import "AppDelegate.h"
#import "UserData.h"
#import "GameViewController.h"

#define kAlertViewDonations 1
#define kAlertViewThanks    2

@implementation StoreClient

@synthesize storeAvailable;

+ (StoreClient *)instance {
	static StoreClient *_instance;
	@synchronized(self) {
		if (!_instance) {
			_instance = [[StoreClient alloc] init];
		}
	}
	return _instance;
}

- (id)init {
	if ((self = [super init])) {
        storeAvailable = [self isStoreAvailable];
        if (storeAvailable) {
            [self requestProductData];
            [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
        }
	}
	return self;
}

- (BOOL)isStoreAvailable {
    return [SKPaymentQueue canMakePayments];
}

- (void)requestProductData {
    SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:
                                  [NSSet setWithObjects: @"de.oklemenz.RubiksFifteen.Donation1",
                                                         @"de.oklemenz.RubiksFifteen.Donation2",
                                                         @"de.oklemenz.RubiksFifteen.Donation3",
                                                         @"de.oklemenz.RubiksFifteen.Donation4", nil]];
    request.delegate = self;
    [request start];
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    storeProducts = response.products;
    storeProducts = [storeProducts sortedArrayUsingComparator:^(id a, id b) {
        SKProduct *p1 = (SKProduct *)a;
        int index1 = (int)[p1.productIdentifier substringFromIndex:p1.productIdentifier.length];
        SKProduct *p2 = (SKProduct *)b;
        int index2 = (int)[p2.productIdentifier substringFromIndex:p2.productIdentifier.length];
        return [[NSNumber numberWithInt:index1] compare:[NSNumber numberWithInt:index2]];
    }];
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
    for (SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchased:
                [self provideProduct:transaction.payment.productIdentifier];
                break;
            case SKPaymentTransactionStateFailed:
                if (transaction.error.code != SKErrorPaymentCancelled) {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"In-App purchase failed!", @"") message:NSLocalizedString(@"The donation was not successful.", @"") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
                    [alert show];
                }
                break;
            case SKPaymentTransactionStateRestored:
                [self provideProduct:transaction.originalTransaction.payment.productIdentifier];
                break;
            default:
                break;
        }
        if (transaction.transactionState != SKPaymentTransactionStatePurchasing) {
            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
        }
    }
}

- (void)purchaseProduct:(NSString *)product {
    SKPayment *payment = [SKPayment paymentWithProductIdentifier:product];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

- (void)provideProduct:(NSString *)product {
    [UserData instance].donationTime = 0;
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Thank you for your donation!", @"") message:@"" delegate:self cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
    alert.tag = kAlertViewThanks;
    [alert show];
}

- (NSArray *)getStoreProducts {
    return storeProducts;
}

- (void)purchaseProductAtIndex:(int)index {
    SKProduct *storeProduct = [storeProducts objectAtIndex:index];
    [self purchaseProduct:storeProduct.productIdentifier];
}

- (void)showDonations {
    NSArray *products = [[StoreClient instance] getStoreProducts];
    if (products != nil && [products count] > 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Please select:", @"") message:@"" delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"") otherButtonTitles:nil];
        for (SKProduct *storeProduct in products) {
            [alert addButtonWithTitle:[self formatProduct:storeProduct]];
        };
        alert.tag = kAlertViewDonations;
        [alert show];
    }
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView.tag == kAlertViewDonations) {
        [[GameViewController instance] storeEnded];
        if (buttonIndex == alertView.cancelButtonIndex) {
            return;
        }
        NSArray *products = [[StoreClient instance] getStoreProducts];
        buttonIndex--;
        if (buttonIndex >= 0 && buttonIndex < [products count]) {
            [self purchaseProductAtIndex:(int)buttonIndex];
        }
    }
}

- (NSString *)formatProduct:(SKProduct *)storeProduct {
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [numberFormatter setLocale:storeProduct.priceLocale];
    NSString *formattedPrice = [numberFormatter stringFromNumber:storeProduct.price];
    return [NSString stringWithFormat:@"%@ %@", storeProduct.localizedTitle, formattedPrice];
}

@end