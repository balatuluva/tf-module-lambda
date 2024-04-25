resource "aws_vpc" "main" {
  cidr_block = "10.0.100.0/16"
}
resource "aws_subnet" "private" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.101.0/24"
  availability_zone = "us-east-1a"
}
resource "aws_subnet" "public" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.102.0/24"
  availability_zone = "us-east-1a"
}
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}
resource "aws_route_table_association" "public" {
  route_table_id = aws_route_table.public.id
  subnet_id = aws_subnet.public.id
}
resource "aws_security_group" "lambda_sg" {
  name = "uat-lambda_sg"
  description = "Allow Outbound Traffic for Lambda"
  vpc_id = aws_vpc.main.id
  ingress {
    description = "DOCDB"
    from_port = 27017
    to_port = 27017
    protocol = "tcp"
    cidr_blocks = aws_subnet.private.cidr_block
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_lambda_function" "lambda" {
  function_name = "uat-lambda"
  handler = "index.test"
  runtime = "nodejs20.x"
  architectures = ["arm64"]
  memory_size = 512
  timeout = 60

  role = aws_iam_role.role.arn

  environment {
    variables = {
      MONGODB_SECRETS = "arn:aws"
    }
  }

  vpc_config {
    security_group_ids = [aws_security_group.lambda_sg.id]
    subnet_ids = [aws_subnet.private.id]
  }
}

resource "aws_codepipeline" "lambda_pipeline" {
  name     = "uat-lambda_pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = "uat-lambda-builds"
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      category = "${}"
      name     = "${}"
      owner    = "${Bala}"
      provider = "${}"
      version  = "1.0.0"
      output_artifacts = ["o/p"]

      configuration = {
        Owner = "${Bala}"
        Repo = "lambda-repo"
        Branch = "develop"
        OAuthToken = "topken"
      }
    }
  }
}
