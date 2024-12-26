# outstagram-terraform

Outstagram 프로젝트에 필요한 AWS 리소스를 생성하는 Terraform입니다.

프로비저닝하고자 하는 환경(dev 혹은 prd)별 디렉토리로 접근하여 "terraform apply -var-file=[환경].tfvars"를 실행하면 해당 환경에 따라 AWS 리소스가 생성됩니다.