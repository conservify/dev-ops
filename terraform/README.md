# Updating Certificates

1. Backup `ssl/letsencrypt` into `ssl/backups`
2. Use `ssh-add` to load server's private key into your SSH agent so that the custom certbot scripts are able to copy the authentication files to the servers.
3. Run `renew-fkdev`
4. Run `renew-fkprod`
5. Use terraform to add the certificates: `cd ssl && teraform plan && teraform apply` This will stay running until the old certificates are removed in step 10.
6. Login to AWS EC2 console.
7. Navigate to the Load Balancers, choose `fkdev-lb`, then the `HTTPS:443` listener.
8. Find the "Actions" drop down and choose "Edit listener".
9. Scroll to the bottom and change Default SSL/TLS certificate to the one added by teraform, paying attention to dates and "Save changes"
10. Choose "Certificates" tab and remove the old certificate.
11. Repeat these steps for `fkprd-lb`
12. Once done, terraform should successfully complete.
