package com.derekgelvez.user.service;

import com.derekgelvez.user.model.User;
import com.derekgelvez.user.model.dto.LoginUserDto;
import com.derekgelvez.user.model.dto.RegisterUserDto;
import com.derekgelvez.user.model.dto.VerifyUserDto;
import com.derekgelvez.user.repository.UserRepository;
import com.derekgelvez.user.response.LoginResponse;
import jakarta.mail.MessagingException;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.LocalDateTime;

@Service
public class AuthenticationService {
    private static final int VERIFICATION_CODE_BOUND = 1_000_000;
    private static final int VERIFICATION_CODE_EXPIRATION_MINUTES = 15;

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final AuthenticationManager authenticationManager;
    private final EmailService emailService;
    private final JwtService jwtService;
    private final SecureRandom secureRandom = new SecureRandom();

    public AuthenticationService(
            UserRepository userRepository,
            PasswordEncoder passwordEncoder,
            AuthenticationManager authenticationManager,
            EmailService emailService,
            JwtService jwtService
    ) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.authenticationManager = authenticationManager;
        this.emailService = emailService;
        this.jwtService = jwtService;
    }

    @Transactional
    public void signup(RegisterUserDto input) {
        if (userRepository.findByEmail(input.getEmail()).isPresent()) {
            throw new IllegalArgumentException("An account with that email already exists");
        }

        User user = new User(
                input.getUsername(),
                input.getEmail(),
                passwordEncoder.encode(input.getPassword())
        );
        user.setVerificationCode(generateVerificationCode());
        user.setVerificationCodeExpiresAt(
                LocalDateTime.now().plusMinutes(VERIFICATION_CODE_EXPIRATION_MINUTES)
        );
        user.setEnabled(false);

        userRepository.save(user);
        sendVerificationEmail(user);
    }

    public LoginResponse authenticate(LoginUserDto input) {
        User user = userRepository.findByEmail(input.getEmail())
                .orElseThrow(() -> new IllegalArgumentException("Invalid email or password"));

        if (!user.isEnabled()) {
            throw new IllegalStateException("Account is not verified");
        }

        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(input.getEmail(), input.getPassword())
        );

        String token = jwtService.generateToken(user.getEmail(), user);
        return new LoginResponse(token, jwtService.getExpirationTime());
    }

    @Transactional
    public void verifyUser(VerifyUserDto input) {
        User user = userRepository.findByEmail(input.getEmail())
                .orElseThrow(() -> new IllegalArgumentException("Invalid verification request"));

        if (user.isEnabled()) {
            throw new IllegalStateException("Account is already verified");
        }
        if (user.getVerificationCodeExpiresAt() == null
                || user.getVerificationCodeExpiresAt().isBefore(LocalDateTime.now())) {
            throw new IllegalStateException("Verification code has expired");
        }
        if (user.getVerificationCode() == null
                || !user.getVerificationCode().equals(input.getVerificationCode())) {
            throw new IllegalArgumentException("Invalid verification code");
        }

        user.setEnabled(true);
        user.setVerificationCode(null);
        user.setVerificationCodeExpiresAt(null);
        userRepository.save(user);
    }

    @Transactional
    public void resendVerificationCode(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("Invalid verification request"));

        if (user.isEnabled()) {
            throw new IllegalStateException("Account is already verified");
        }

        user.setVerificationCode(generateVerificationCode());
        user.setVerificationCodeExpiresAt(
                LocalDateTime.now().plusMinutes(VERIFICATION_CODE_EXPIRATION_MINUTES)
        );
        userRepository.save(user);
        sendVerificationEmail(user);
    }

    private void sendVerificationEmail(User user) {
        String htmlMessage = "<html><body>"
                + "<h2>Welcome to our app!</h2>"
                + "<p>Enter this verification code in the app:</p>"
                + "<p><strong>" + user.getVerificationCode() + "</strong></p>"
                + "</body></html>";

        try {
            emailService.sendVerificationEmail(
                    user.getEmail(),
                    "Account Verification",
                    htmlMessage
            );
        } catch (MessagingException exception) {
            throw new IllegalStateException("Unable to send verification email", exception);
        }
    }

    private String generateVerificationCode() {
        return String.format("%06d", secureRandom.nextInt(VERIFICATION_CODE_BOUND));
    }
}
