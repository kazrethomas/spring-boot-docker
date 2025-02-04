package com.example.demo;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HelloController {

    @Value("${YOUR_NAME}")
    private String yourName;

    @GetMapping("/api/hello")
    public String hello() {
        return "Hello " + yourName;
    }
}
