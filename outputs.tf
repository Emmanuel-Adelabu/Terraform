output "dev_ip"{
    value = aws_instance.emu_instance.public_ip
}