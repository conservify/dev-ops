package main

import (
	"fmt"
	"log"

	"github.com/nlopes/slack"
)

type Notifier struct {
	URL     string
	Channel string
	Token   string
}

func NewSlackNotifier(url, channel, token string) (n *Notifier, err error) {
	return &Notifier{
		URL:     url,
		Channel: channel,
		Token:   token,
	}, nil
}

func (n *Notifier) NotifyReceived(meta *UploadMeta) error {
	if len(n.Channel) == 0 || len(n.Token) == 0 {
		log.Printf("notifications: no configuration")
		return nil
	}
	if meta == nil {
		log.Printf("notifications: no meta")
		return nil
	}

	api := slack.New(n.Token)

	message := fmt.Sprintf("diagnostics: %v (%v?id=%v)", meta.Phrase, n.URL, meta.Batch)
	channelID, ts, err := api.PostMessage(n.Channel, slack.MsgOptionText(message, false))
	if err != nil {
		return err
	}

	log.Printf("done %v %v", channelID, ts)

	return nil
}
