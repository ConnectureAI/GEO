
import { Request, Response } from 'express';
import { CompetitorService } from '../services/competitor.service';

const competitorService = new CompetitorService();

export const getCompetitors = async (req: Request, res: Response) => {
  try {
    const { clinicId } = req.params;
    const competitors = await competitorService.getCompetitors(clinicId);
    res.status(200).json({ success: true, data: competitors });
  } catch (error) {
    res.status(500).json({ success: false, error: (error as Error).message });
  }
};

export const addCompetitor = async (req: Request, res: Response) => {
  try {
    const competitor = await competitorService.addCompetitor(req.body);
    res.status(201).json({ success: true, data: competitor });
  } catch (error) {
    res.status(500).json({ success: false, error: (error as Error).message });
  }
};

export const getCompetitorAnalysis = async (req: Request, res: Response) => {
  try {
    const { competitorId } = req.params;
    const analysis = await competitorService.getCompetitorAnalysis(competitorId);
    res.status(200).json({ success: true, data: analysis });
  } catch (error) {
    res.status(500).json({ success: false, error: (error as Error).message });
  }
};
