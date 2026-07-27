package com.sentinelle.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.Date;

@Service
public class JwtService {

    @Value("${jwt.secret}")
    private String secret;

    @Value("${jwt.expiration}")
    private long expiration;

    public String generateToken(String username){

        return Jwts.builder()

                .setSubject(username)

                .setIssuedAt(new Date())

                .setExpiration(new Date(System.currentTimeMillis()+expiration))

                .signWith(SignatureAlgorithm.HS256,secret)

                .compact();

    }

    public String extractUsername(String token){

        Claims claims = Jwts.parser()

                .setSigningKey(secret)

                .parseClaimsJws(token)

                .getBody();

        return claims.getSubject();

    }

    public boolean isTokenValid(String token){

        Claims claims = Jwts.parser()

                .setSigningKey(secret)

                .parseClaimsJws(token)

                .getBody();

        return claims.getExpiration().after(new Date());

    }

}
