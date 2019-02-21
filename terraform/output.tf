# output "ebs_att_id" {
  # value = "${aws_volume_attachment.ebs_att.id}"
# }

# output "ebs_att_device_name" {
  # value = "${aws_volume_attachment.ebs_att.device_name}"
# }

output "public_ip" {
 value = "${aws_instance.prometheus.public_ip}"
}
