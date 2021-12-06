# Role =============================================
resource "aws_iam_role" "codedeploy_role" {
  name               = "${var.project_name}-ecsCodeDeployRole"
  assume_role_policy = data.aws_iam_policy_document.codedeploy_role_assume_role_policy_document.json

  tags = {
    Name = "${var.project_name}-ecsCodeDeployRole"
  }
}

# Role Policy Attachment =============================================
resource "aws_iam_role_policy_attachment" "codedeploy_role_attachment" {
  role       = aws_iam_role.codedeploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}

# Policy =============================================
data "aws_iam_policy_document" "codedeploy_role_assume_role_policy_document" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codedeploy.amazonaws.com"]
    }
  }
}