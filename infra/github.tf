resource "github_use_ssh_key" "ssh_key_local" {
	title = var.SSH_KEY_NAME
	key = file(~/.ssh/var.SSH_KEY_NAME)
}
