#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, IPFTestRunnerConfigurationType) {
  IPFTestRunnerConfigurationTypeUpload = 0,
  IPFTestRunnerConfigurationTypeDownload = 1,
  IPFTestRunnerConfigurationTypeServer = 2
};

typedef NS_ENUM(NSUInteger, IPFTestRunnerProtocol) {
  IPFTestRunnerProtocolTCP = 0,
  IPFTestRunnerProtocolUDP = 1
};
