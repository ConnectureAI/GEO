
import express from 'express';
import { json } from 'body-parser';
import competitorRoutes from './routes/competitor.routes';
import { initDatabase } from './database';

const app = express();
app.use(json());

app.use('/api/v1', competitorRoutes);

const port = process.env.PORT || 3000;

const startServer = async () => {
  await initDatabase();
  app.listen(port, () => {
    console.log(`Server is running on port ${port}`);
  });
};

startServer();
