terraform {
	required_providers{
		digitalocean = {
			source = "digitalocean/digitalocean"
			version ="~> 2.0"
		}
		github = {
			source = "integrations/github"
			version = "4.17.0"
		}
	}
}

provider "digitalocean" {}
provider "github" {}
