package com.sentinelle.entity;

import jakarta.persistence.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "users")
public class User {

    @Id

    @GeneratedValue(strategy = GenerationType.IDENTITY)

    private Long id;

    @Column(nullable = false, unique = true)

    private String username;

    @Column(nullable = false)

    private String password;

    @Column(nullable = false)

    private String role;

    @Column(nullable = false)

    private boolean enabled;

    @Column(nullable = false)

    private boolean linuxAccount;

    @Column(nullable = false)

    private boolean otpEnabled;

    @Column(length = 255)

    private String otpSecret;

    @Column

    private LocalDateTime createdAt;

    @Column

    private LocalDateTime lastLogin;

    public User() {
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id=id;
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username){
        this.username=username;
    }

    public String getPassword(){
        return password;
    }

    public void setPassword(String password){
        this.password=password;
    }

    public String getRole(){
        return role;
    }

    public void setRole(String role){
        this.role=role;
    }

    public boolean isEnabled(){
        return enabled;
    }

    public void setEnabled(boolean enabled){
        this.enabled=enabled;
    }

    public boolean isLinuxAccount(){
        return linuxAccount;
    }

    public void setLinuxAccount(boolean linuxAccount){
        this.linuxAccount=linuxAccount;
    }

    public boolean isOtpEnabled(){
        return otpEnabled;
    }

    public void setOtpEnabled(boolean otpEnabled){
        this.otpEnabled=otpEnabled;
    }

    public String getOtpSecret(){
        return otpSecret;
    }

    public void setOtpSecret(String otpSecret){
        this.otpSecret=otpSecret;
    }

    public LocalDateTime getCreatedAt(){
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt){
        this.createdAt=createdAt;
    }

    public LocalDateTime getLastLogin(){
        return lastLogin;
    }

    public void setLastLogin(LocalDateTime lastLogin){
        this.lastLogin=lastLogin;
    }

}
