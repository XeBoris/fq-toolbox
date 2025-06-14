#restric configurations:
export RESTIC_PACK_SIZE=128
export RESTIC_PASSWORD=<your RESTIC Password>

# s3 configuration:
export RESTIC_REPOSITORY=<RESTIC Repository>
export AWS_ACCESS_KEY_ID=<AWS Access Key>
export AWS_SECRET_ACCESS_KEY=<AWS Secret Key

# configure everything else:
# eg: s3://backup-bucket/backup_partiton/first
#     -> export FQ_S3_BACKUP_PATH=backup_partiton/first
export FQ_S3_BACKUP_PATH=<your backup partition>
