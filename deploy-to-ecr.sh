#!/bin/bash

# Deploy to AWS ECR Script
# This script builds and pushes your Docker image to Amazon ECR

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
AWS_REGION=${AWS_REGION:-us-east-1}
ECR_REPO_NAME=${ECR_REPO_NAME:-course-feedback-app}
IMAGE_TAG=${IMAGE_TAG:-latest}

echo -e "${YELLOW}======================================${NC}"
echo -e "${YELLOW}  Deploying to AWS ECR${NC}"
echo -e "${YELLOW}======================================${NC}"

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed. Please install it first.${NC}"
    exit 1
fi

# Get AWS Account ID
echo -e "\n${YELLOW}🔍 Getting AWS Account ID...${NC}"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
if [ -z "$AWS_ACCOUNT_ID" ]; then
    echo -e "${RED}❌ Failed to get AWS Account ID. Please check your AWS credentials.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ AWS Account ID: $AWS_ACCOUNT_ID${NC}"

# ECR Repository URL
ECR_REPO_URL="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO_NAME"

# Create ECR repository if it doesn't exist
echo -e "\n${YELLOW}🏗️  Creating ECR repository (if not exists)...${NC}"
aws ecr describe-repositories --repository-names $ECR_REPO_NAME --region $AWS_REGION 2>/dev/null || \
    aws ecr create-repository --repository-name $ECR_REPO_NAME --region $AWS_REGION
echo -e "${GREEN}✅ ECR repository ready${NC}"

# Login to ECR
echo -e "\n${YELLOW}🔐 Logging in to Amazon ECR...${NC}"
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO_URL
echo -e "${GREEN}✅ Logged in to ECR${NC}"

# Build Docker image
echo -e "\n${YELLOW}🏗️  Building Docker image...${NC}"
docker build -t $ECR_REPO_NAME:$IMAGE_TAG .
echo -e "${GREEN}✅ Docker image built successfully${NC}"

# Tag image for ECR
echo -e "\n${YELLOW}🏷️  Tagging image for ECR...${NC}"
docker tag $ECR_REPO_NAME:$IMAGE_TAG $ECR_REPO_URL:$IMAGE_TAG
docker tag $ECR_REPO_NAME:$IMAGE_TAG $ECR_REPO_URL:latest
echo -e "${GREEN}✅ Image tagged${NC}"

# Push to ECR
echo -e "\n${YELLOW}⬆️  Pushing image to ECR...${NC}"
docker push $ECR_REPO_URL:$IMAGE_TAG
docker push $ECR_REPO_URL:latest
echo -e "${GREEN}✅ Image pushed to ECR${NC}"

# Display image URI
echo -e "\n${GREEN}======================================${NC}"
echo -e "${GREEN}✅ Deployment Successful!${NC}"
echo -e "${GREEN}======================================${NC}"
echo -e "\n${YELLOW}📦 Image URI:${NC}"
echo -e "   $ECR_REPO_URL:$IMAGE_TAG"
echo -e "   $ECR_REPO_URL:latest"

echo -e "\n${YELLOW}📝 Next Steps:${NC}"
echo -e "   1. Update your ECS task definition or App Runner with the image URI"
echo -e "   2. Deploy to your ECS service or create a new App Runner service"
echo -e "   3. Configure environment variables and secrets"
echo -e "   4. Test your application"

echo -e "\n${YELLOW}💡 Quick Commands:${NC}"
echo -e "   # Update ECS service:"
echo -e "   aws ecs update-service --cluster CLUSTER_NAME --service SERVICE_NAME --force-new-deployment"
echo -e "\n   # View images in ECR:"
echo -e "   aws ecr list-images --repository-name $ECR_REPO_NAME --region $AWS_REGION"

