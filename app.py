import time
from locust import HttpUser, task, between

class QuickStartUser(HttpUser):
	wait_time = between(1, 5)
	@task
	def hello(self):
		self.client.get("/about")

	@task(3)
	def hello2(self):
		self.client.get("/blog")

	def on_start(self):
		self.client.get("/legal")

	def on_stop(self):
		self.client.get("/legal")
