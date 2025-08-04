
import { Sequelize } from 'sequelize';
import { initCompetitorModel } from './models/competitor.model';

const sequelize = new Sequelize('seo_platform_dev', 'seo_dev_user', 'DevStrongP@ss123!', {
  host: 'localhost',
  port: 5432,
  dialect: 'postgres',
  logging: false, // Set to console.log to see SQL queries
});

export const initDatabase = async () => {
  try {
    await sequelize.authenticate();
    console.log('Connection has been established successfully.');

    // Initialize models
    initCompetitorModel(sequelize);

    // Sync all models
    await sequelize.sync({ alter: true });
    console.log('All models were synchronized successfully.');
  } catch (error) {
    console.error('Unable to connect to the database:', error);
    process.exit(1);
  }
};

export default sequelize;
