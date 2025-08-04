
import { Router } from 'express';
import {
  getCompetitors,
  addCompetitor,
  getCompetitorAnalysis,
} from '../controllers/competitor.controller';

const router = Router();

router.get('/clinics/:clinicId/competitors', getCompetitors);
router.post('/clinics/:clinicId/competitors', addCompetitor);
router.get('/competitors/:competitorId/analysis', getCompetitorAnalysis);

export default router;
