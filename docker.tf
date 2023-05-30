resource "null_resource" "docker_install" {

  provisioner "local-exec" {
    command = "git clone https://github.com/triabagus/php-mongodb-crud.git"

  }
}
resource "docker_image" "my_image" {
  name          = "php1.0"
  build {
    context    = "~/.Dockerfile"
  }
  depends_on = [
    null_resource.docker_install
  ]
}

resource "null_resource" "docker_build" {

  provisioner "local-exec" {
    command = "docker login --username=reddy8096 --password=Darwinbox@123"
  }

  provisioner "local-exec" {
    command = "docker build -t reddy8096/task-terraform:php1.0 ."
  }

  provisioner "local-exec" {
    command = "docker push reddy8096/task-terraform:php1.0"
  }
}
