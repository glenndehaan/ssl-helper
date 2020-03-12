# SSL Helper

A small bash utility for checking/managing SSL Certifcates

## Usage
### View Certificate Details
* Add an SSL certificate in the following structure:
```
- example.com
    - example.com/example.com.crt (Certificate)
    - example.com/example.com.csr (Certificate Request)
    - example.com/example.com.key (Private Key)
```

* Download the `src/ssl-helper.sh` from GitHub and store it somewhere on your machine.
* Run the utility as follows `./ssl-helper.sh ./example.com`
* Select option 1 from the list

#### Example Output
```

-------------------------------------------------------------------------------
Result for example.com

Private Key v/s Certificate Request: OK
Certificate v/s Certificate Request: OK
Certificate v/s Private Key: OK

Raw output (MD5):
Private Key: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
Certificate Request: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
Certificate: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
-------------------------------------------------------------------------------
Certificate Request Info:

Country Code: NL
State or Province Name: Zuid-Holland
Locality Name: Rotterdam
Organization Name: Example Org.
Organizational Unit Name: IT
Common Name: example.com
Email address: domains@example.com
-------------------------------------------------------------------------------
Certificate Info:

Not Valid Before: Mar 4 00:00:00 2020 GMT
Not Valid After: Mar 5 23:59:59 2021 GMT
-------------------------------------------------------------------------------

```

### Create a Private Key/Certificate Request pair
* Download the `src/ssl-helper.sh` and `ssl-helper.defaults.conf` from GitHub and store it somewhere on your machine.
* Update the `ssl-helper.defaults.conf` to match your organisation details
* Run the utility as follows `./ssl-helper.sh example.com`
* Select option 2 from the list

## License

MIT
