package com.sentinelle.controller;

import com.sentinelle.service.AlertsService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/alerts")
public class AlertsController {

    @Autowired
    private AlertsService alertsService;

    @GetMapping
    public ResponseEntity<Map<String, Object>> getAlerts() {
        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "Alertes récupérées avec succès");
        response.put("data", alertsService.getActiveAlerts());
        response.put("timestamp", LocalDateTime.now().toString());
        return ResponseEntity.ok(response);
    }
}
