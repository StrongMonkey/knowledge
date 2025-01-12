package cmd

import (
	"encoding/json"
	"fmt"
	"github.com/spf13/cobra"
)

type ClientGetDataset struct {
	Client
}

func (s *ClientGetDataset) Customize(cmd *cobra.Command) {
	cmd.Use = "get-dataset <dataset-id>"
	cmd.Short = "Get a dataset"
	cmd.Args = cobra.ExactArgs(1)
}

func (s *ClientGetDataset) Run(cmd *cobra.Command, args []string) error {
	c, err := s.getClient()
	if err != nil {
		return err
	}

	datasetID := args[0]

	ds, err := c.GetDataset(cmd.Context(), datasetID)
	if err != nil {
		return fmt.Errorf("failed to get dataset: %w", err)
	}

	if ds == nil {
		fmt.Println("dataset not found")
		return fmt.Errorf("dataset not found")
	}

	jsonOutput, err := json.Marshal(ds)
	if err != nil {
		return fmt.Errorf("failed to marshal dataset: %w", err)
	}

	fmt.Println(string(jsonOutput))
	return nil
}
