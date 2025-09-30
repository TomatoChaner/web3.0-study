package events

import (
	"context"
	"fmt"
	"sync"
	"time"

	"github.com/gagliardetto/solana-go"
	"github.com/gagliardetto/solana-go/rpc"
	"github.com/gorilla/websocket"
	"github.com/sirupsen/logrus"

	"solana-go-assignment/internal/config"
	"solana-go-assignment/internal/utils"
)

// EventType represents different types of events
type EventType string

const (
	EventTypeSlotChange    EventType = "slot_change"
	EventTypeAccount       EventType = "account"
	EventTypeSignature     EventType = "signature"
	EventTypeProgram       EventType = "program"
	EventTypeTransaction   EventType = "transaction"
)

// Event represents a generic event
type Event struct {
	Type      EventType   `json:"type"`
	Timestamp time.Time   `json:"timestamp"`
	Data      interface{} `json:"data"`
}

// SlotChangeEvent represents a slot change event
type SlotChangeEvent struct {
	Slot   uint64 `json:"slot"`
	Parent uint64 `json:"parent"`
	Root   uint64 `json:"root"`
}

// AccountChangeEvent represents an account change event
type AccountChangeEvent struct {
	Account   string `json:"account"`
	Lamports  uint64 `json:"lamports"`
	Owner     string `json:"owner"`
	DataSize  int    `json:"data_size"`
	RentEpoch uint64 `json:"rent_epoch"`
}

// SignatureEvent represents a signature notification event
type SignatureEvent struct {
	Signature string `json:"signature"`
	Slot      uint64 `json:"slot"`
	Status    string `json:"status"`
	Error     string `json:"error,omitempty"`
}

// ProgramEvent represents a program account change event
type ProgramEvent struct {
	Account   string `json:"account"`
	Program   string `json:"program"`
	Lamports  uint64 `json:"lamports"`
	DataSize  int    `json:"data_size"`
}

// EventHandler is a function that handles events
type EventHandler func(event *Event) error

// EventStats represents event statistics
type EventStats struct {
	TotalEvents     uint64            `json:"total_events"`
	EventsByType    map[EventType]uint64 `json:"events_by_type"`
	LastEventTime   time.Time         `json:"last_event_time"`
	EventsPerSecond float64           `json:"events_per_second"`
	StartTime       time.Time         `json:"start_time"`
}

// Subscriber manages WebSocket subscriptions to Solana events
type Subscriber struct {
	wsURL      string
	network    config.NetworkType
	conn       *websocket.Conn
	handlers   map[EventType][]EventHandler
	stats      *EventStats
	logger     *logrus.Logger
	ctx        context.Context
	cancel     context.CancelFunc
	mu         sync.RWMutex
	wg         sync.WaitGroup
	subscriptions map[string]uint64 // subscription ID mapping
}

// NewSubscriber creates a new event subscriber
func NewSubscriber(wsURL string, network config.NetworkType) (*Subscriber, error) {
	logger := logrus.New()
	logger.SetLevel(logrus.InfoLevel)

	ctx, cancel := context.WithCancel(context.Background())

	subscriber := &Subscriber{
		wsURL:         wsURL,
		network:       network,
		handlers:      make(map[EventType][]EventHandler),
		stats:         &EventStats{
			EventsByType: make(map[EventType]uint64),
			StartTime:    time.Now(),
		},
		logger:        logger,
		ctx:           ctx,
		cancel:        cancel,
		subscriptions: make(map[string]uint64),
	}

	// Connect to WebSocket
	if err := subscriber.connect(); err != nil {
		cancel()
		return nil, fmt.Errorf("failed to connect to WebSocket: %v", err)
	}

	// Start event processing
	subscriber.wg.Add(1)
	go subscriber.processEvents()

	subscriber.logger.WithFields(logrus.Fields{
		"network": network,
		"ws_url":  wsURL,
	}).Info("Event subscriber initialized")

	return subscriber, nil
}

// connect establishes WebSocket connection
func (s *Subscriber) connect() error {
	conn, _, err := websocket.DefaultDialer.Dial(s.wsURL, nil)
	if err != nil {
		return fmt.Errorf("failed to dial WebSocket: %v", err)
	}

	s.conn = conn
	s.logger.Info("WebSocket connection established")
	return nil
}

// Close closes the subscriber and all connections
func (s *Subscriber) Close() {
	s.logger.Info("Closing event subscriber")
	
	s.cancel()
	
	if s.conn != nil {
		s.conn.Close()
	}
	
	s.wg.Wait()
	
	s.logger.Info("Event subscriber closed")
}

// AddHandler adds an event handler for a specific event type
func (s *Subscriber) AddHandler(eventType EventType, handler EventHandler) {
	s.mu.Lock()
	defer s.mu.Unlock()

	s.handlers[eventType] = append(s.handlers[eventType], handler)
	
	s.logger.WithFields(logrus.Fields{
		"event_type": eventType,
		"handlers":   len(s.handlers[eventType]),
	}).Debug("Event handler added")
}

// RemoveHandlers removes all handlers for a specific event type
func (s *Subscriber) RemoveHandlers(eventType EventType) {
	s.mu.Lock()
	defer s.mu.Unlock()

	delete(s.handlers, eventType)
	
	s.logger.WithField("event_type", eventType).Debug("Event handlers removed")
}

// SubscribeToSlots subscribes to slot change notifications
func (s *Subscriber) SubscribeToSlots() error {
	request := map[string]interface{}{
		"jsonrpc": "2.0",
		"id":      1,
		"method":  "slotSubscribe",
		"params":  []interface{}{},
	}

	if err := s.conn.WriteJSON(request); err != nil {
		return fmt.Errorf("failed to send slot subscription: %v", err)
	}

	s.logger.Info("Subscribed to slot changes")
	return nil
}

// SubscribeToAccount subscribes to account change notifications
func (s *Subscriber) SubscribeToAccount(address string, commitment rpc.CommitmentType) error {
	pubkey, err := solana.PublicKeyFromBase58(address)
	if err != nil {
		return fmt.Errorf("invalid public key: %v", err)
	}

	request := map[string]interface{}{
		"jsonrpc": "2.0",
		"id":      2,
		"method":  "accountSubscribe",
		"params": []interface{}{
			pubkey.String(),
			map[string]interface{}{
				"commitment": string(commitment),
				"encoding":   "base64",
			},
		},
	}

	if err := s.conn.WriteJSON(request); err != nil {
		return fmt.Errorf("failed to send account subscription: %v", err)
	}

	s.logger.WithFields(logrus.Fields{
		"address":    utils.FormatAddress(pubkey),
		"commitment": commitment,
	}).Info("Subscribed to account changes")

	return nil
}

// SubscribeToSignature subscribes to signature notifications
func (s *Subscriber) SubscribeToSignature(signature string, commitment rpc.CommitmentType) error {
	sig, err := solana.SignatureFromBase58(signature)
	if err != nil {
		return fmt.Errorf("invalid signature: %v", err)
	}

	request := map[string]interface{}{
		"jsonrpc": "2.0",
		"id":      3,
		"method":  "signatureSubscribe",
		"params": []interface{}{
			sig.String(),
			map[string]interface{}{
				"commitment": string(commitment),
			},
		},
	}

	if err := s.conn.WriteJSON(request); err != nil {
		return fmt.Errorf("failed to send signature subscription: %v", err)
	}

	s.logger.WithFields(logrus.Fields{
		"signature":  utils.FormatSignature(sig),
		"commitment": commitment,
	}).Info("Subscribed to signature notifications")

	return nil
}

// SubscribeToProgram subscribes to program account changes
func (s *Subscriber) SubscribeToProgram(programID string, commitment rpc.CommitmentType) error {
	pubkey, err := solana.PublicKeyFromBase58(programID)
	if err != nil {
		return fmt.Errorf("invalid program ID: %v", err)
	}

	request := map[string]interface{}{
		"jsonrpc": "2.0",
		"id":      4,
		"method":  "programSubscribe",
		"params": []interface{}{
			pubkey.String(),
			map[string]interface{}{
				"commitment": string(commitment),
				"encoding":   "base64",
			},
		},
	}

	if err := s.conn.WriteJSON(request); err != nil {
		return fmt.Errorf("failed to send program subscription: %v", err)
	}

	s.logger.WithFields(logrus.Fields{
		"program_id": utils.FormatAddress(pubkey),
		"commitment": commitment,
	}).Info("Subscribed to program account changes")

	return nil
}

// processEvents processes incoming WebSocket events
func (s *Subscriber) processEvents() {
	defer s.wg.Done()

	for {
		select {
		case <-s.ctx.Done():
			return
		default:
			var message map[string]interface{}
			if err := s.conn.ReadJSON(&message); err != nil {
				s.logger.WithError(err).Error("Failed to read WebSocket message")
				continue
			}

			if err := s.handleMessage(message); err != nil {
				s.logger.WithError(err).Error("Failed to handle message")
			}
		}
	}
}

// handleMessage handles incoming WebSocket messages
func (s *Subscriber) handleMessage(message map[string]interface{}) error {
	// Check if it's a subscription response
	if method, ok := message["method"].(string); ok {
		return s.handleNotification(method, message)
	}

	// Check if it's a subscription confirmation
	if result, ok := message["result"]; ok {
		s.logger.WithField("result", result).Debug("Subscription confirmed")
		return nil
	}

	return nil
}

// handleNotification handles subscription notifications
func (s *Subscriber) handleNotification(method string, message map[string]interface{}) error {
	params, ok := message["params"].(map[string]interface{})
	if !ok {
		return fmt.Errorf("invalid notification params")
	}

	result, ok := params["result"].(map[string]interface{})
	if !ok {
		return fmt.Errorf("invalid notification result")
	}

	var event *Event
	var err error

	switch method {
	case "slotNotification":
		event, err = s.parseSlotNotification(result)
	case "accountNotification":
		event, err = s.parseAccountNotification(result)
	case "signatureNotification":
		event, err = s.parseSignatureNotification(result)
	case "programNotification":
		event, err = s.parseProgramNotification(result)
	default:
		s.logger.WithField("method", method).Debug("Unknown notification method")
		return nil
	}

	if err != nil {
		return fmt.Errorf("failed to parse %s: %v", method, err)
	}

	if event != nil {
		s.dispatchEvent(event)
	}

	return nil
}

// parseSlotNotification parses slot change notifications
func (s *Subscriber) parseSlotNotification(result map[string]interface{}) (*Event, error) {
	slot, ok := result["slot"].(float64)
	if !ok {
		return nil, fmt.Errorf("invalid slot value")
	}

	parent, _ := result["parent"].(float64)
	root, _ := result["root"].(float64)

	slotEvent := &SlotChangeEvent{
		Slot:   uint64(slot),
		Parent: uint64(parent),
		Root:   uint64(root),
	}

	return &Event{
		Type:      EventTypeSlotChange,
		Timestamp: time.Now(),
		Data:      slotEvent,
	}, nil
}

// parseAccountNotification parses account change notifications
func (s *Subscriber) parseAccountNotification(result map[string]interface{}) (*Event, error) {
	value, ok := result["value"].(map[string]interface{})
	if !ok {
		return nil, fmt.Errorf("invalid account value")
	}

	lamports, _ := value["lamports"].(float64)
	owner, _ := value["owner"].(string)
	rentEpoch, _ := value["rentEpoch"].(float64)

	var dataSize int
	if data, ok := value["data"].([]interface{}); ok && len(data) > 0 {
		if dataStr, ok := data[0].(string); ok {
			dataSize = len(dataStr)
		}
	}

	accountEvent := &AccountChangeEvent{
		Lamports:  uint64(lamports),
		Owner:     owner,
		DataSize:  dataSize,
		RentEpoch: uint64(rentEpoch),
	}

	return &Event{
		Type:      EventTypeAccount,
		Timestamp: time.Now(),
		Data:      accountEvent,
	}, nil
}

// parseSignatureNotification parses signature notifications
func (s *Subscriber) parseSignatureNotification(result map[string]interface{}) (*Event, error) {
	value, ok := result["value"].(map[string]interface{})
	if !ok {
		return nil, fmt.Errorf("invalid signature value")
	}

	slot, _ := value["slot"].(float64)
	
	status := "confirmed"
	errorMsg := ""
	if err, ok := value["err"]; ok && err != nil {
		status = "failed"
		errorMsg = fmt.Sprintf("%v", err)
	}

	signatureEvent := &SignatureEvent{
		Slot:   uint64(slot),
		Status: status,
		Error:  errorMsg,
	}

	return &Event{
		Type:      EventTypeSignature,
		Timestamp: time.Now(),
		Data:      signatureEvent,
	}, nil
}

// parseProgramNotification parses program account change notifications
func (s *Subscriber) parseProgramNotification(result map[string]interface{}) (*Event, error) {
	value, ok := result["value"].(map[string]interface{})
	if !ok {
		return nil, fmt.Errorf("invalid program value")
	}

	account, _ := value["pubkey"].(string)
	accountData, _ := value["account"].(map[string]interface{})
	
	lamports, _ := accountData["lamports"].(float64)
	owner, _ := accountData["owner"].(string)

	var dataSize int
	if data, ok := accountData["data"].([]interface{}); ok && len(data) > 0 {
		if dataStr, ok := data[0].(string); ok {
			dataSize = len(dataStr)
		}
	}

	programEvent := &ProgramEvent{
		Account:  account,
		Program:  owner,
		Lamports: uint64(lamports),
		DataSize: dataSize,
	}

	return &Event{
		Type:      EventTypeProgram,
		Timestamp: time.Now(),
		Data:      programEvent,
	}, nil
}

// dispatchEvent dispatches an event to all registered handlers
func (s *Subscriber) dispatchEvent(event *Event) {
	s.mu.RLock()
	handlers := s.handlers[event.Type]
	s.mu.RUnlock()

	// Update statistics
	s.updateStats(event)

	// Execute handlers concurrently
	var wg sync.WaitGroup
	for _, handler := range handlers {
		wg.Add(1)
		go func(h EventHandler) {
			defer wg.Done()
			if err := h(event); err != nil {
				s.logger.WithError(err).Error("Event handler failed")
			}
		}(handler)
	}
	wg.Wait()

	s.logger.WithFields(logrus.Fields{
		"event_type": event.Type,
		"handlers":   len(handlers),
		"timestamp":  event.Timestamp,
	}).Debug("Event dispatched")
}

// updateStats updates event statistics
func (s *Subscriber) updateStats(event *Event) {
	s.mu.Lock()
	defer s.mu.Unlock()

	s.stats.TotalEvents++
	s.stats.EventsByType[event.Type]++
	s.stats.LastEventTime = event.Timestamp

	// Calculate events per second
	duration := time.Since(s.stats.StartTime).Seconds()
	if duration > 0 {
		s.stats.EventsPerSecond = float64(s.stats.TotalEvents) / duration
	}
}

// GetStats returns current event statistics
func (s *Subscriber) GetStats() *EventStats {
	s.mu.RLock()
	defer s.mu.RUnlock()

	// Create a copy to avoid race conditions
	stats := &EventStats{
		TotalEvents:     s.stats.TotalEvents,
		EventsByType:    make(map[EventType]uint64),
		LastEventTime:   s.stats.LastEventTime,
		EventsPerSecond: s.stats.EventsPerSecond,
		StartTime:       s.stats.StartTime,
	}

	for k, v := range s.stats.EventsByType {
		stats.EventsByType[k] = v
	}

	return stats
}

// PrintStats prints current statistics
func (s *Subscriber) PrintStats() {
	stats := s.GetStats()
	
	s.logger.WithFields(logrus.Fields{
		"total_events":      stats.TotalEvents,
		"events_per_second": fmt.Sprintf("%.2f", stats.EventsPerSecond),
		"uptime":           utils.FormatDuration(time.Since(stats.StartTime)),
		"last_event":       utils.FormatTimestamp(stats.LastEventTime.Unix()),
	}).Info("Event statistics")

	for eventType, count := range stats.EventsByType {
		s.logger.WithFields(logrus.Fields{
			"event_type": eventType,
			"count":      count,
			"percentage": utils.CalculatePercentage(count, stats.TotalEvents),
		}).Info("Event type statistics")
	}
}