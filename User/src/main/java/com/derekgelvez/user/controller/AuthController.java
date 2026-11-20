package com.derekgelvez.user.controller;

import com.derekgelvez.user.model.dto.LoginUserDto;
import com.derekgelvez.user.model.dto.RegisterUserDto;
import com.derekgelvez.user.model.dto.ResendVerificationDto;
import com.derekgelvez.user.model.dto.VerifyUserDto;
import com.derekgelvez.user.response.MessageResponse;
import com.derekgelvez.user.response.LoginResponse;
import com.derekgelvez.user.service.AuthenticationService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RequestMapping("/auth")
@RestController
public class AuthController {
    private final AuthenticationService authenticationService;

    public AuthController(AuthenticationService authenticationService) {
        this.authenticationService = authenticationService;
    }

    @PostMapping("/signup")
    public ResponseEntity<MessageResponse> register(@RequestBody RegisterUserDto registerUserDto) {
        authenticationService.signup(registerUserDto);
        return ResponseEntity.ok(new MessageResponse("Verification email sent"));
    }

    @PostMapping("/login")
    public ResponseEntity<LoginResponse> authenticate(@RequestBody LoginUserDto loginUserDto) {
        return ResponseEntity.ok(authenticationService.authenticate(loginUserDto));
    }

    @PostMapping("/verify")
    public ResponseEntity<MessageResponse> verifyUser(@RequestBody VerifyUserDto verifyUserDto) {
        authenticationService.verifyUser(verifyUserDto);
        return ResponseEntity.ok(new MessageResponse("Account verified successfully"));
    }

    @PostMapping("/resend-verification")
    public ResponseEntity<MessageResponse> resendVerificationCode(
            @RequestBody ResendVerificationDto request
    ) {
        authenticationService.resendVerificationCode(request.getEmail());
        return ResponseEntity.ok(new MessageResponse("Verification code sent"));
    }
}
