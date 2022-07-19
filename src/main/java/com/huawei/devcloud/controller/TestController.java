package com.huawei.devcloud.controller;

import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping(value = "test")
public class TestController {


    @RequestMapping
    public String index() {
        return "hello world";
    }

}
