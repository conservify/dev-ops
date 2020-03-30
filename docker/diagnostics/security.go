package main

import (
	"context"
	"encoding/base64"
	"fmt"
	"net/http"
	"strings"
	"time"

	jwtgo "github.com/dgrijalva/jwt-go"
)

func NewToken(now time.Time) *jwtgo.Token {
	scopes := []string{"api:access"}

	token := jwtgo.New(jwtgo.SigningMethodHS512)
	token.Claims = jwtgo.MapClaims{
		"iat":    now.Unix(),
		"exp":    now.Add(time.Hour * 168 * 52).Unix(),
		"scopes": scopes,
	}

	return token
}

func stripBearer(token string) string {
	return strings.ReplaceAll(token, "Bearer ", "")
}

func getToken(req *http.Request) string {
	header := req.Header.Get("Authorization")
	if len(header) > 0 {
		return stripBearer(header)
	}
	param := req.URL.Query()["token"]
	if len(param) > 0 {
		return stripBearer(param[0])
	}
	return ""
}

func secure(h func(context.Context, *Services, http.ResponseWriter, *http.Request) error) func(context.Context, *Services, http.ResponseWriter, *http.Request) error {
	return func(ctx context.Context, services *Services, w http.ResponseWriter, req *http.Request) error {
		authorization := getToken(req)
		if authorization == "" {
			return StatusError{http.StatusUnauthorized, fmt.Errorf("unauthorized")}
		}

		key, err := base64.StdEncoding.DecodeString(SessionKey)
		if err != nil {
			return fmt.Errorf("error decoding session key: %v", err)
		}

		token, err := jwtgo.Parse(authorization, func(token *jwtgo.Token) (interface{}, error) {
			if _, ok := token.Method.(*jwtgo.SigningMethodHMAC); !ok {
				return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
			}
			return key, nil
		})
		if err != nil {
			return StatusError{http.StatusUnauthorized, err}
		}

		if _, ok := token.Claims.(jwtgo.MapClaims); ok && token.Valid {
			return h(ctx, services, w, req)
		}

		return StatusError{http.StatusUnauthorized, fmt.Errorf("unauthorized")}
	}
}
