// SPDX-FileCopyrightText: 2023 Hoang Nguyen <folliekazetani@protonmail.com>
//
// SPDX-License-Identifier: Apache-2.0

package main

import (
	"github.com/pulumi/pulumi-aws-native/sdk/go/aws"
	"github.com/pulumi/pulumi-aws-native/sdk/go/aws/s3"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

func main() {
	pulumi.Run(func(ctx *pulumi.Context) error {
		awsProvider, err := aws.NewProvider(ctx, "staging", &aws.ProviderArgs{
			Region: pulumi.String("us-east-1"),
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
