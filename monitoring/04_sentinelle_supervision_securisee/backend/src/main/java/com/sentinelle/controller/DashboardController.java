package com.sentinelle.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.Map;
import java.util.HashMap;

@RestController
@RequestMapping("/api/dashboard")
public class DashboardController {

    @GetMapping("/overview")
    public ResponseEntity<Map<String, Object>> getOverview() {
        Map<String, Object> data = new HashMap<>();
        data.put("status", "UP");
        data.put("version", "4.0");
        data.put("hostname", "ubuntu-server");
        return ResponseEntity.ok(data);
    }
}
