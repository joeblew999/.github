# Well-Known Endpoints

Simple guide for implementing essential `.well-known` endpoints for modern web authentication and security.

## What are .well-known endpoints?

Standard URLs that browsers and services expect to find at `https://yourdomain.com/.well-known/` for security and authentication features.


## References

https://github.com/moul/awesome-well-known looks really useful !!


https://en.m.wikipedia.org/wiki/Well-known_URI#List_of_well-known_URIs also is pretty good.

- **IANA Registry**: https://www.iana.org/assignments/well-known-uris/ (official list)
- **MDN Docs**: https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/Resource_URIs
- **RFC 8615**: Well-Known URIs standard

## Essential Endpoints

### 1. Change Password
**URL:** `/.well-known/change-password`  
**Purpose:** Browsers redirect here when user wants to change password  
**Action:** Redirect to your password change page

```
HTTP/1.1 302 Found
Location: https://yourdomain.com/account/password
```

### 2. WebAuthn (Passkeys)
**URL:** `/.well-known/webauthn`  
**Purpose:** Passkey configuration for browsers  
**Content-Type:** `application/json`

```json
{
  "origins": ["https://yourdomain.com"]
}
```

### 3. Security Contact
**URL:** `/.well-known/security.txt`  
**Purpose:** How security researchers can contact you  
**Content-Type:** `text/plain`

```
Contact: mailto:security@yourdomain.com
Expires: 2025-12-31T23:59:59.000Z
Preferred-Languages: en
```

## Implementation in Go

```go
func setupWellKnown(mux *http.ServeMux) {
    // Change password redirect
    mux.HandleFunc("/.well-known/change-password", func(w http.ResponseWriter, r *http.Request) {
        http.Redirect(w, r, "/account/password", http.StatusFound)
    })
    
    // WebAuthn config
    mux.HandleFunc("/.well-known/webauthn", func(w http.ResponseWriter, r *http.Request) {
        w.Header().Set("Content-Type", "application/json")
        w.Write([]byte(`{"origins":["https://yourdomain.com"]}`))
    })
    
    // Security contact
    mux.HandleFunc("/.well-known/security.txt", func(w http.ResponseWriter, r *http.Request) {
        w.Header().Set("Content-Type", "text/plain")
        w.Write([]byte("Contact: mailto:security@yourdomain.com\nExpires: 2025-12-31T23:59:59.000Z\n"))
    })
}
```

## Testing

```bash
curl -I https://yourdomain.com/.well-known/change-password
curl https://yourdomain.com/.well-known/webauthn
curl https://yourdomain.com/.well-known/security.txt
```


## Environment Variables

Add to your `.env`:

```bash
DOMAIN=yourdomain.com
SECURITY_EMAIL=security@yourdomain.com
```

## Next Steps

1. Implement the three essential endpoints
2. Test with browsers
3. Add more only when needed

That's it! Start simple.
