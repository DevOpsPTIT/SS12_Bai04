package com.example.springvpsapp;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.net.InetAddress;
import java.net.UnknownHostException;
import java.util.Map;

@RestController
public class AppInfoController {

    @Value("${spring.profiles.active:default}")
    private String activeProfile;

    @Value("${app.version:1.0.0}")
    private String appVersion;

    @GetMapping("/")
    public Map<String, String> info() throws UnknownHostException {
        return Map.of(
            "app",      "spring-vps-app",
            "version",  appVersion,
            "profile",  activeProfile,
            "host",     InetAddress.getLocalHost().getHostName(),
            "java",     System.getProperty("java.version"),
            "status",   "running"
        );
    }

    @GetMapping("/api/hello")
    public Map<String, String> hello() {
        return Map.of(
            "message", "Hello from VPS! 🚀",
            "profile", activeProfile
        );
    }
}
