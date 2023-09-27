package main

import (
	"os"

	"github.com/pulumi/pulumi-aws-native/sdk/go/aws"
	"github.com/pulumi/pulumi-aws-native/sdk/go/aws/s3"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

func main() {
	pulumi.Run(func(ctx *pulumi.Context) error {
		awsProvider, err := aws.NewProvider(ctx, "staging", &aws.ProviderArgs{
			Region:               pulumi.String("us-east-1"),
			AccessKey:            pulumi.String(os.Getenv("AWS_ACCESS_KEY_ID")),
			SecretKey:            pulumi.String(os.Getenv("AWS_SECRET_ACCESS_KEY")),
			SkipMetadataApiCheck: pulumi.Bool(true),
		})
		if err != nil {
			return err
		}

		// Let's create a simple S3 bucket as a good start
		bucketName := "hoangnh-managed-test-bucket"
		_, err = s3.NewBucket(ctx, bucketName, &s3.BucketArgs{
			BucketName: pulumi.String(bucketName),
		}, pulumi.Provider(awsProvider))
		if err != nil {
			return err
		}

		return nil
	})
}
