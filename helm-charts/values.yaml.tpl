host: ${cluster_name}.hosted.unionai.cloud
clusterName: ${cluster_name}
orgName: ${org_name}
provider: aws
storage:
  provider: aws
  authType: iam
  bucketName: ${bucket_name}
  fastRegistrationBucketName: ${bucket_name}
  region: ${region}
  enableMultiContainer: true
secrets:
  admin:
    create: true
    clientId: ${client_id}
    clientSecret: ${client_secret}
additionalServiceAccountAnnotations:
  eks.amazonaws.com/role-arn: ${union_flyte_role_arn}
userRoleAnnotationKey: eks.amazonaws.com/role-arn
userRoleAnnotationValue: ${union_flyte_role_arn}
fluentbit:
  serviceAccount:
    annotations:
      eks.amazonaws.com/role-arn: ${union_flyte_role_arn}
